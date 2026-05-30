<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Gestor Financiero Pro</title>

<link href="https://unpkg.com/tabulator-tables@6.3.0/dist/css/tabulator.min.css" rel="stylesheet">
<script src="https://unpkg.com/tabulator-tables@6.3.0/dist/js/tabulator.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<style>
:root{--p:#2563eb;--bg:#f3f4f6;--card:#fff}
body{margin:0;font-family:Segoe UI,Arial;background:var(--bg)}
header{background:var(--p);color:#fff;padding:16px}
.container{padding:20px;max-width:1600px;margin:auto}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:15px}
.card{background:var(--card);padding:18px;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,.08)}
.big{font-size:1.8rem;font-weight:bold}
.toolbar{display:flex;gap:10px;flex-wrap:wrap;margin:15px 0}
button{padding:10px 14px;border:none;border-radius:8px;cursor:pointer}
.chartwrap,.tablewrap{background:#fff;padding:15px;border-radius:12px;margin-top:15px}
.dark{--bg:#111827;--card:#1f2937;color:#fff}
.dark .chartwrap,.dark .tablewrap{background:#1f2937}
canvas{max-height:350px}
</style>
</head>
<body>
<header>
<h1>💼 Gestor Financiero Profesional</h1>
</header>

<div class="container">

<div class="grid">
<div class="card"><div>Balance</div><div id="balance" class="big">$0</div></div>
<div class="card"><div>Ingresos</div><div id="ingresos" class="big">$0</div></div>
<div class="card"><div>Gastos</div><div id="gastos" class="big">$0</div></div>
<div class="card"><div>Ahorro (%)</div><div id="ahorro" class="big">0%</div></div>
</div>

<div class="toolbar">
<button onclick="addRow()">➕ Movimiento</button>
<button onclick="table.download('xlsx','finanzas.xlsx',{sheetName:'Finanzas'})">📊 Excel</button>
<button onclick="table.download('csv','finanzas.csv')">📄 CSV</button>
<button onclick="toggleDark()">🌙 Modo oscuro</button>
</div>

<div class="tablewrap">
<div id="tabla"></div>
</div>

<div class="grid">
<div class="chartwrap"><canvas id="bar"></canvas></div>
<div class="chartwrap"><canvas id="pie"></canvas></div>
</div>

</div>

<script>
const storage="finanzas_pro_v1";

let data=JSON.parse(localStorage.getItem(storage))||[
{
fecha:new Date().toISOString().slice(0,10),
categoria:"Sueldo",
descripcion:"Ingreso",
cuenta:"Banco",
tipo:"Ingreso",
monto:1500000
}
];

const table=new Tabulator("#tabla",{
height:"550px",
layout:"fitColumns",
data:data,
columns:[
{title:"Fecha",field:"fecha",editor:"input"},
{title:"Categoría",field:"categoria",editor:"list",editorParams:{values:["Sueldo","Comida","Transporte","Servicios","Salud","Ocio","Inversión","Otros"]}},
{title:"Descripción",field:"descripcion",editor:"input"},
{title:"Cuenta",field:"cuenta",editor:"input"},
{title:"Tipo",field:"tipo",editor:"list",editorParams:{values:["Ingreso","Gasto"]}},
{title:"Monto",field:"monto",editor:"number"},
{title:"Eliminar",formatter:()=> "🗑️", cellClick:(e,c)=>{c.getRow().delete();save();}}
],
cellEdited:save
});

function save(){
localStorage.setItem(storage,JSON.stringify(table.getData()));
update();
}

function addRow(){
table.addRow({
fecha:new Date().toISOString().slice(0,10),
categoria:"Otros",
descripcion:"",
cuenta:"",
tipo:"Gasto",
monto:0
});
save();
}

function money(v){
return "$"+Number(v).toLocaleString("es-CL");
}

let barChart,pieChart;

function update(){
const rows=table.getData();

let ingresos=0,gastos=0;
const categorias={};

rows.forEach(r=>{
let m=Number(r.monto)||0;

if(r.tipo==="Ingreso"){
ingresos+=m;
}else{
gastos+=m;
categorias[r.categoria]=(categorias[r.categoria]||0)+m;
}
});

let balance=ingresos-gastos;
let ahorro=ingresos?((balance/ingresos)*100):0;

balanceEl.textContent=money(balance);
ingresosEl.textContent=money(ingresos);
gastosEl.textContent=money(gastos);
ahorroEl.textContent=ahorro.toFixed(1)+"%";

if(barChart)barChart.destroy();
barChart=new Chart(document.getElementById("bar"),{
type:"bar",
data:{labels:["Ingresos","Gastos","Balance"],
datasets:[{data:[ingresos,gastos,balance]}]}
});

if(pieChart)pieChart.destroy();
pieChart=new Chart(document.getElementById("pie"),{
type:"pie",
data:{
labels:Object.keys(categorias),
datasets:[{data:Object.values(categorias)}]
}
});
}

const balanceEl=document.getElementById("balance");
const ingresosEl=document.getElementById("ingresos");
const gastosEl=document.getElementById("gastos");
const ahorroEl=document.getElementById("ahorro");

function toggleDark(){
document.body.classList.toggle("dark");
}

update();
</script>
</body>
</html>
