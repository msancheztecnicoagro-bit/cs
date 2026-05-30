<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestor Financiero Personal</title>

    <link href="https://unpkg.com/tabulator-tables@6.3.0/dist/css/tabulator.min.css" rel="stylesheet">
    
    <script src="https://unpkg.com/tabulator-tables@6.3.0/dist/js/tabulator.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    <style>
        :root {
            --bg-light: #f4f6f9;
            --bg-dark: #121212;
            --card-light: #fff;
            --card-dark: #1e1e1e;
            --text-light: #333;
            --text-dark: #fff;
        }

        body {
            font-family: Arial, sans-serif;
            background: var(--bg-light);
            color: var(--text-light);
            margin: 0;
            padding: 20px;
            transition: background-color 0.3s, color 0.3s;
        }

        .container {
            max-width: 1400px;
            margin: auto;
        }

        h1 {
            text-align: center;
        }

        .cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }

        .card {
            background: var(--card-light);
            padding: 15px;
            border-radius: 10px;
            box-shadow: 0 2px 6px rgba(0,0,0,.1);
            text-align: center;
            transition: background-color 0.3s;
        }

        .value {
            font-size: 1.6rem;
            font-weight: bold;
            margin-top: 10px;
        }

        .actions {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-bottom: 15px;
        }

        button {
            padding: 10px 14px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            background-color: #2563eb;
            color: white;
            font-weight: bold;
            transition: opacity 0.2s;
        }

        button:hover {
            opacity: 0.8;
        }

        #table {
            background: var(--card-light);
            border-radius: 8px;
            overflow: hidden;
            transition: background-color 0.3s;
        }

        .charts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }

        .chart-container {
            background: var(--card-light);
            padding: 15px;
            border-radius: 10px;
            box-shadow: 0 2px 6px rgba(0,0,0,.1);
            transition: background-color 0.3s;
            position: relative;
            height: 350px;
        }

        /* --- Modo Oscuro --- */
        body.dark {
            background: var(--bg-dark);
            color: var(--text-dark);
        }

        body.dark .card,
        body.dark #table,
        body.dark .chart-container {
            background: var(--card-dark);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>💰 Gestor Financiero Personal</h1>

        <div class="cards">
            <div class="card">
                <div>Balance</div>
                <div class="value" id="balance">$0</div>
            </div>
            <div class="card">
                <div>Ingresos</div>
                <div class="value" id="ingresos">$0</div>
            </div>
            <div class="card">
                <div>Gastos</div>
                <div class="value" id="gastos">$0</div>
            </div>
            <div class="card">
                <div>Ahorro (%)</div>
                <div class="value" id="ahorro">0%</div>
            </div>
        </div>

        <div class="actions">
            <button onclick="agregarFila()">➕ Agregar fila</button>
            <button onclick="exportarExcel()">📊 Exportar a Excel</button>
            <button onclick="exportarCSV()">📄 Exportar a CSV</button>
            <button onclick="toggleDark()">🌙 Modo oscuro</button>
        </div>

        <div id="table"></div>

        <h2>Resumen Visual</h2>
        <div class="charts-grid">
            <div class="chart-container">
                <canvas id="graficoBarras"></canvas>
            </div>
            <div class="chart-container">
                <canvas id="graficoTorta"></canvas>
            </div>
        </div>
    </div>

    <script>
        // 1. Cargar datos iniciales
        let datos = JSON.parse(localStorage.getItem("gastosExcel")) || [
            {
                fecha: new Date().toISOString().split('T')[0],
                categoria: "Sueldo",
                descripcion: "Ingreso inicial",
                cuenta: "Banco",
                ingreso: 1000000,
                gasto: 0
            }
        ];

        // 2. Configurar la tabla Tabulator
        const table = new Tabulator("#table", {
            height: "400px",
            layout: "fitColumns",
            data: datos,
            reactiveData: true,
            columns: [
                {title: "Fecha", field: "fecha", editor: "input"},
                {
                    title: "Categoría", 
                    field: "categoria", 
                    editor: "list", 
                    editorParams: {
                        values: ["Sueldo", "Alimentación", "Transporte", "Vivienda", "Servicios", "Salud", "Ocio", "Educación", "Inversión", "Otros"]
                    }
                },
                {title: "Descripción", field: "descripcion", editor: "input"},
                {title: "Cuenta", field: "cuenta", editor: "input"},
                {title: "Ingreso", field: "ingreso", editor: "number"},
                {title: "Gasto", field: "gasto", editor: "number"},
                {
                    title: "Saldo", 
                    field: "saldo", 
                    mutator: function(value, data) {
                        return (Number(data.ingreso) || 0) - (Number(data.gasto) || 0);
                    }
                },
                {
                    title: "Eliminar", 
                    width: 90, 
                    hozAlign: "center",
                    formatter: function() { return "🗑️"; }, 
                    cellClick: function(e, cell) {
                        cell.getRow().delete();
                        guardar();
                    }
                }
            ],
            cellEdited: function() { guardar(); }
        });

        // 3. Funciones principales
        function guardar() {
            localStorage.setItem("gastosExcel", JSON.stringify(table.getData()));
            actualizar();
        }

        function agregarFila() {
            table.addRow({
                fecha: new Date().toISOString().split('T')[0],
                categoria: "Otros",
                descripcion: "",
                cuenta: "",
                ingreso: 0,
                gasto: 0
            }, true);
            guardar();
        }

        function actualizar() {
            const data = table.getData();
            let ingresos = 0, gastos = 0;
            let gastosPorCategoria = {};

            data.forEach(r => {
                let ingresoActual = Number(r.ingreso) || 0;
                let gastoActual = Number(r.gasto) || 0;
                let categoria = r.categoria || "Sin categoría";

                ingresos += ingresoActual;
                gastos += gastoActual;

                // Sumar gastos por categoría para el gráfico de torta
                if (gastoActual > 0) {
                    gastosPorCategoria[categoria] = (gastosPorCategoria[categoria] || 0) + gastoActual;
                }
            });

            let balance = ingresos - gastos;
            let porcentajeAhorro = ingresos > 0 ? ((balance / ingresos) * 100) : 0;

            // Actualizar tarjetas en el DOM
            document.getElementById("ingresos").innerText = "$" + ingresos.toLocaleString('es-CL');
            document.getElementById("gastos").innerText = "$" + gastos.toLocaleString('es-CL');
            document.getElementById("balance").innerText = "$" + balance.toLocaleString('es-CL');
            document.getElementById("ahorro").innerText = porcentajeAhorro.toFixed(1) + "%";

            // Actualizar gráficos
            actualizarGraficos(ingresos, gastos, gastosPorCategoria);
        }

        // 4. Exportaciones y UI
        function exportarCSV() {
            table.download("csv", "gastos.csv");
        }

        function exportarExcel() {
            table.download("xlsx", "gastos.xlsx", {sheetName: "Movimientos"});
        }

        function toggleDark() {
            document.body.classList.toggle("dark");
        }

        // 5. Gestión de Gráficos
        let chartBarras, chartTorta;

        function actualizarGraficos(ingresos, gastos, categorias) {
            // Configurar modo oscuro para los gráficos
            Chart.defaults.color = document.body.classList.contains('dark') ? '#fff' : '#666';

            // Gráfico de Barras (Ingresos vs Gastos)
            const ctxBarras = document.getElementById("graficoBarras");
            if(chartBarras) chartBarras.destroy();

            chartBarras = new Chart(ctxBarras, {
                type: "bar",
                data: {
                    labels: ["Ingresos", "Gastos"],
                    datasets: [{
                        label: 'Monto Total ($)',
                        data: [ingresos, gastos],
                        backgroundColor: ['#10b981', '#ef4444'],
                        borderRadius: 6
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { title: { display: true, text: 'Flujo de Caja' } }
                }
            });

            // Gráfico de Torta (Gastos por Categoría)
            const ctxTorta = document.getElementById("graficoTorta");
            if(chartTorta) chartTorta.destroy();

            const etiquetasCategorias = Object.keys(categorias);
            const datosCategorias = Object.values(categorias);

            chartTorta = new Chart(ctxTorta, {
                type: "doughnut",
                data: {
                    labels: etiquetasCategorias,
                    datasets: [{
                        data: datosCategorias,
                        backgroundColor: ['#ef4444', '#f59e0b', '#3b82f6', '#8b5cf6', '#ec4899', '#14b8a6', '#f97316', '#64748b', '#84cc16'],
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { title: { display: true, text: 'Desglose de Gastos' } }
                }
            });
        }

        // Detectar cambio de tema para repintar gráficos
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.attributeName === 'class') {
                    actualizar();
                }
            });
        });
        observer.observe(document.body, { attributes: true });

        // Inicializar cálculos en la primera carga
        actualizar();
    </script>
</body>
</html>
