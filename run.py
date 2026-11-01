"""Construye y comprueba la entrega. Python >=3.10 y SQLite >=3.37; sin paquetes externos."""
from pathlib import Path
from decimal import Decimal, ROUND_HALF_UP
import argparse, hashlib, json, sqlite3, sys, platform
from datetime import datetime, timezone
from contextlib import nullcontext

ROOT = Path(__file__).resolve().parent
TABLES = ['dim_categorias','dim_productos','dim_clientes','dim_tiendas','dim_fecha','fact_ventas']

def connect(path):
    db=sqlite3.connect(path)
    db.execute('PRAGMA foreign_keys=ON')
    db.create_function('importe_venta',3,lambda q,p,d: float((Decimal(str(q))*Decimal(str(p))*(1-Decimal(str(d))/100)).quantize(Decimal('.01'),rounding=ROUND_HALF_UP)),deterministic=True)
    return db

def statements(text):
    buf=''
    for line in text.splitlines(True):
        buf+=line
        if sqlite3.complete_statement(buf):
            yield buf
            buf=''
    if buf.strip():
        raise ValueError('Sentencia incompleta')

def execute_all(db,text):
    outputs=[]
    for sql in statements(text):
        cur=db.execute(sql)
        if cur.description:
            outputs.append({'sql':sql,'columns':[x[0] for x in cur.description],'rows':cur.fetchall()})
    return outputs

def snapshot(db):
    return {t: db.execute('SELECT * FROM '+t+' ORDER BY 1').fetchall() for t in TABLES+['raw_statements']}

def build(db):
    db.executescript((ROOT/'01_schema.sql').read_text(encoding='utf-8'))
    db.execute('BEGIN')
    try:
        for n,line in enumerate((ROOT/'originales/02_carga.sql').read_text(encoding='utf-8-sig').splitlines(),1):
            if line.startswith('INSERT INTO public.'):
                target=line.split('public.')[1].split(' ')[0]
                values=(n,target,line,hashlib.sha256(line.encode()).hexdigest())
                db.execute('INSERT OR IGNORE INTO raw_statements(source_line,target_table,original_sql,sha256) VALUES(?,?,?,?)',values)
                stored=db.execute('SELECT target_table,original_sql,sha256 FROM raw_statements WHERE source_line=?',(n,)).fetchone()
                assert stored==values[1:], 'RAW cambió: se necesita migración explícita'
        db.commit()
    except Exception:
        db.rollback()
        raise
    try:
        db.executescript((ROOT/'02_data.sql').read_text(encoding='utf-8'))
    except Exception:
        db.rollback()
        raise

def md_table(columns, rows):
    def cell(x): return str(x if x is not None else 'NULL').replace('|','\\|').replace('\n',' ')
    return '| '+' | '.join(columns)+' |\n|'+'|'.join(['---']*len(columns))+'|\n'+''.join('| '+' | '.join(map(cell,row))+' |\n' for row in rows)

def verify(db):
    checks=[]
    def check(name,condition):
        assert condition,name
        checks.append({'prueba':name,'resultado':'PASS'})
    check('foreign_keys activado',db.execute('PRAGMA foreign_keys').fetchone()[0]==1)
    check('foreign_key_check vacío',db.execute('PRAGMA foreign_key_check').fetchall()==[])
    check('integrity_check ok',db.execute('PRAGMA integrity_check').fetchone()[0]=='ok')
    check('Todas las tablas tienen PK',all(any(r[5] for r in db.execute('PRAGMA table_info('+t+')')) for t in TABLES+['raw_statements']))
    for t in TABLES:
        check('RAW/CORE '+t,db.execute('SELECT COUNT(*) FROM '+t).fetchone()[0]==db.execute('SELECT COUNT(*) FROM raw_statements WHERE target_table=?',(t,)).fetchone()[0])
    hashes=json.loads((ROOT/'reports/originales_sha256.json').read_text())
    check('Originales SHA256 intactos',all(hashlib.sha256((ROOT/'originales'/name).read_bytes()).hexdigest()==digest for name,digest in hashes.items()))
    with connect(':memory:') as reference:
        reference.executescript((ROOT/'01_schema.sql').read_text(encoding='utf-8'))
        reference.executescript((ROOT/'originales/02_carga.sql').read_text(encoding='utf-8-sig').replace('public.',''))
        reference.execute("UPDATE dim_clientes SET email=NULLIF(email,'NULL'),ciudad=NULLIF(ciudad,'NULL')")
        for t in TABLES:
            check('Trazabilidad valores completos '+t,reference.execute('SELECT * FROM '+t+' ORDER BY 1').fetchall()==db.execute('SELECT * FROM '+t+' ORDER BY 1').fetchall())
    expected_indexes={'ix_sales_date':('fact_ventas','fecha_id'),'ix_sales_product':('fact_ventas','producto_id'),'ix_sales_customer':('fact_ventas','cliente_id'),'ix_sales_store':('fact_ventas','tienda_id'),'ix_product_category':('dim_productos','categoria_id')}
    for name,(table,column) in expected_indexes.items():
        check('Índice '+name, name in [r[1] for r in db.execute('PRAGMA index_list('+table+')')] and [r[2] for r in db.execute('PRAGMA index_info('+name+')')]==[column])
    check('Cuatro FK de hechos y FK producto-categoría',len(db.execute('PRAGMA foreign_key_list(fact_ventas)').fetchall())==4 and len(db.execute('PRAGMA foreign_key_list(dim_productos)').fetchall())==1)
    expected_warnings={1,2,4,5,7,8,10,11,12,25,30,31,32}
    warnings=db.execute('SELECT v.venta_id FROM fact_ventas v JOIN dim_clientes c USING(cliente_id) JOIN dim_fecha f USING(fecha_id) WHERE f.fecha<c.fecha_alta').fetchall()
    check('Trece advertencias de origen identificadas',set(r[0] for r in warnings)==expected_warnings)
    baseline=snapshot(db)
    for label,sql in [
        ('PRIMARY KEY','INSERT INTO dim_categorias VALUES(1,\'otra\',NULL)'),
        ('UNIQUE',"INSERT INTO dim_categorias VALUES(999,'Figuras',NULL)"),
        ('NOT NULL',"INSERT INTO dim_categorias VALUES(999,NULL,NULL)"),
        ('CHECK rango','UPDATE fact_ventas SET descuento=101 WHERE venta_id=1'),
        ('CHECK cantidad','UPDATE fact_ventas SET cantidad=-1 WHERE venta_id=1'),
        ('STRICT conversión inválida',"UPDATE fact_ventas SET cantidad='abc' WHERE venta_id=1"),
        ('FOREIGN KEY','UPDATE fact_ventas SET producto_id=99999 WHERE venta_id=1'),
        ('CHECK fecha imposible',"UPDATE dim_fecha SET fecha='2026-02-30' WHERE fecha_id=1"),
        ('trigger UPDATE',"UPDATE fact_ventas SET devuelto=1,fecha_devolucion='2020-01-01' WHERE venta_id=1"),
        ('trigger INSERT',"INSERT INTO fact_ventas(fecha_id,cliente_id,producto_id,tienda_id,cantidad,precio_unitario,coste_unitario,devuelto,fecha_devolucion) VALUES(1,1,1,1,1,10,3,1,'2020-01-01')"),
    ]:
        db.execute('SAVEPOINT invalid')
        rejected=False
        try: db.execute(sql)
        except sqlite3.IntegrityError: rejected=True
        finally:
            db.execute('ROLLBACK TO invalid')
            db.execute('RELEASE invalid')
        check('Rechazo '+label,rejected)
    db.execute('BEGIN')
    db.execute('UPDATE dim_productos SET precio_base=precio_base+1 WHERE producto_id=1')
    check('ROLLBACK cambia estado dentro de transacción',snapshot(db)!=baseline)
    db.rollback()
    check('ROLLBACK restaura todo CORE y RAW',snapshot(db)==baseline)
    db.execute('BEGIN')
    db.execute("INSERT INTO dim_productos(producto_id,nombre_producto,categoria_id,precio_base,coste_base) VALUES(999,'DEMO',1,1,0)")
    check('DEFAULT activo',db.execute('SELECT activo FROM dim_productos WHERE producto_id=999').fetchone()[0]==1)
    db.rollback()
    check('Función Python registrada',db.execute('SELECT importe_venta(2,12.9,10)').fetchone()[0]==23.22)
    for view in ['vw_ventas_detalle','vw_movimientos']:
        check('Vista '+view,db.execute('SELECT COUNT(*) FROM '+view).fetchone()[0]>0)
    queries=json.loads((ROOT/'queries.json').read_text(encoding='utf-8'))
    check('Exactamente diez consultas',len(queries)==10 and (ROOT/'03_eda.sql').read_text(encoding='utf-8').count('-- ANALISIS ')==10)
    results=[]
    for i,(question,tech,sql,interp) in enumerate(queries,1):
        cur=db.execute(sql)
        results.append({'id':i,'question':question,'technique':tech,'sql':sql,'interpretation':interp,'columns':[x[0] for x in cur.description],'rows':cur.fetchall()})
        check(f'Consulta {i:02d} ejecutada',bool(results[-1]['rows']))
    controls=execute_all(db,(ROOT/'04_quality_checks.sql').read_text(encoding='utf-8'))
    # Los controles 2,3,4,5 y 8 deben devolver cero anomalías técnicas.
    for index in [1,2,3,4,7]:
        check('Control técnico Q'+str(index+1),not controls[index]['rows'])
    # Introducir anomalías reversibles demuestra que los controles las detectan.
    db.execute('SAVEPOINT quality_demo')
    db.execute('UPDATE dim_fecha SET anio=1900 WHERE fecha_id=1')
    check('Detector de calendario detecta error inyectado',bool(execute_all(db,(ROOT/'04_quality_checks.sql').read_text(encoding='utf-8'))[2]['rows']))
    db.execute('ROLLBACK TO quality_demo'); db.execute('RELEASE quality_demo')
    columns=[r[1] for r in db.execute('PRAGMA table_info(fact_ventas)') if r[1]!='venta_id']
    db.execute('SAVEPOINT duplicate_demo')
    db.execute('INSERT INTO fact_ventas('+','.join(columns)+') SELECT '+','.join(columns)+' FROM fact_ventas WHERE venta_id=1')
    check('Detector de duplicados detecta línea inyectada',bool(execute_all(db,(ROOT/'04_quality_checks.sql').read_text(encoding='utf-8'))[1]['rows']))
    db.execute('ROLLBACK TO duplicate_demo'); db.execute('RELEASE duplicate_demo')
    check('Pruebas de calidad no persisten',snapshot(db)==baseline)
    db.execute('CREATE TEMP TABLE dml_probe(id INTEGER PRIMARY KEY,note TEXT)')
    db.execute("INSERT INTO dml_probe VALUES(1,'original')")
    check('INSERT funcional',db.execute('SELECT COUNT(*) FROM dml_probe').fetchone()[0]==1)
    db.execute("UPDATE dml_probe SET note='nuevo' WHERE id=1")
    check('UPDATE funcional',db.execute('SELECT note FROM dml_probe').fetchone()[0]=='nuevo')
    db.execute('DELETE FROM dml_probe WHERE id=1')
    check('DELETE funcional',db.execute('SELECT COUNT(*) FROM dml_probe').fetchone()[0]==0)
    db.execute('DROP TABLE dml_probe'); db.commit()
    cents=lambda x: Decimal(str(x)).quantize(Decimal('.01'),rounding=ROUND_HALF_UP)
    gross=Decimal('0'); sales=Decimal('0'); refunds=Decimal('0')
    for qty,price,discount,returned in db.execute('SELECT cantidad,precio_unitario,descuento,devuelto FROM fact_ventas'):
        gross+=cents(Decimal(qty)*Decimal(str(price)))
        amount=cents(Decimal(qty)*Decimal(str(price))*(1-Decimal(str(discount))/100))
        sales+=amount
        if returned: refunds+=amount
    actual=db.execute('SELECT ROUND(SUM(importe_antes_descuento),2),ROUND(SUM(importe_descuento),2),ROUND(SUM(importe_venta),2) FROM vw_ventas_detalle').fetchone()
    check('Bruto, descuento y ventas conciliados con Decimal',list(map(cents,actual))==[gross,gross-sales,sales])
    movements=db.execute("SELECT ROUND(SUM(CASE WHEN tipo='VENTA' THEN importe ELSE 0 END),2),ROUND(-SUM(CASE WHEN tipo='DEVOLUCION' THEN importe ELSE 0 END),2),ROUND(SUM(importe),2) FROM vw_movimientos").fetchone()
    check('Ventas, devoluciones y neto conciliados con Decimal',list(map(cents,movements))==[sales,refunds,sales-refunds])
    check('Movimientos: 35 ventas positivas y 4 devoluciones negativas',db.execute("SELECT COUNT(*) FROM vw_movimientos WHERE tipo='VENTA' AND importe>0").fetchone()[0]==35 and db.execute("SELECT COUNT(*) FROM vw_movimientos WHERE tipo='DEVOLUCION' AND importe<0").fetchone()[0]==4)
    check('Regresión de redondeo: líneas 6 y 30',db.execute('SELECT venta_id,importe_venta FROM vw_ventas_detalle WHERE venta_id IN (6,30) ORDER BY venta_id').fetchall()==[(6,52.16),(30,23.66)])
    check('Precios y descuentos de fuente admiten céntimos y puntos básicos',all(Decimal(str(p))==cents(p) and Decimal(str(d))==cents(d) for p,d in db.execute('SELECT precio_unitario,descuento FROM fact_ventas')))
    eda_output=execute_all(db,(ROOT/'03_eda.sql').read_text(encoding='utf-8'))
    check('Resultados de 03_eda coinciden con informe',all(a['rows']==b['rows'] for a,b in zip(eda_output[-10:],results)))
    check('03_eda completo ejecutado sin cambios persistentes',snapshot(db)==baseline)
    build(db)
    check('Segunda ejecución sin duplicados ni cambios',snapshot(db)==baseline)
    check('Venta bruta menos devolución igual a ingreso neto',abs(db.execute('SELECT SUM(importe_bruto)-SUM(CASE WHEN devuelto=1 THEN importe_bruto ELSE 0 END) FROM vw_ventas_detalle').fetchone()[0]-db.execute('SELECT SUM(importe) FROM vw_movimientos').fetchone()[0])<1e-7)
    return checks,results,controls

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--verify',action='store_true',help='Reconstruye en base temporal limpia; conserva la entregada')
    args=parser.parse_args()
    reports=ROOT/'reports'; reports.mkdir(exist_ok=True)
    with nullcontext():
        path=':memory:' if args.verify else ROOT/'tienda.sqlite'
        with connect(path) as db:
            build(db)
            checks,results,controls=verify(db)
            counts={t:db.execute('SELECT COUNT(*) FROM '+t).fetchone()[0] for t in TABLES}
            summary={'project_root':str(ROOT),'executed_at_utc':datetime.now(timezone.utc).isoformat(),'python':sys.version,'sqlite':sqlite3.sqlite_version,'platform':platform.platform(),'mode':'base temporal limpia' if args.verify else 'base entregada','counts':counts,'checks':checks,'quality':controls}
        (reports/'pruebas.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
        (reports/'resultados.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
        text='# Diez análisis ejecutados\n\nDatos sintéticos recuperados. Moneda: EUR según documentación original. Resultados calculados con SQLite, sin estimaciones.\n\n'
        for r in results:
            text+=f"## Q{r['id']:02d}. {r['question']}\n\n{r['technique']}\n\n```sql\n{r['sql']};\n```\n\n"+md_table(r['columns'],r['rows'])+'\n'+r['interpretation']+'\n\n'
        (reports/'analisis.md').write_text(text,encoding='utf-8')
        (reports/'PRUEBAS.md').write_text('# Informe de ejecución real\n\n'+f"Ubicación ejecutada: {ROOT}. Fecha UTC: {summary['executed_at_utc']}.\n\nPython {sys.version}; SQLite {sqlite3.sqlite_version}. Modo: {summary['mode']}.\n\n"+md_table(['Tabla','Filas'],counts.items())+'\n'+md_table(['Prueba','Estado'],[(x['prueba'],x['resultado']) for x in checks])+'\n## Calidad observada\n\n'+''.join(md_table(c['columns'],c['rows'])+'\n' for c in controls),encoding='utf-8')
        print(json.dumps({'checks_pass':len(checks),'counts':counts,'database':str(path) if not args.verify else 'base limpia en memoria'},ensure_ascii=False))

if __name__=='__main__': main()
