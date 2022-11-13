function initialiseChartElement(element)
{
    let context = element.getAttribute('avalanche:data-source');

    var options = {
        chart: {
            type: 'area',
            parentHeightOffset: 0,
            fontFamily: 'inherit',
            height: 240,
            toolbar: {
                show: false
            },
            dataLabels: {
                enabled: true
            },
            animations: {
                enabled: true
            },
            tooltip: {
                theme: 'dark'
            },
            stacked: true,
        },
        dataLabels: {
            enabled: false
        },
        grid: {
            show: false
        },
        legend: {
            show: false
        },
        series: [
            {
                name: 'Used',
                data: []
            },
        ],
        noData: {
            text: 'Loading graph'
        },
        xaxis: {
            type: 'datetime',
            labels: {
                format: 'HH:mm:ss',
                show: true
            }
        },
    };
    var chart = new ApexCharts(element, options);
    chart.render();

    if (context !== 'memory')
    {
        return;
    }

    setInterval(ev => {
        updateChart(element, chart);
        return true;
    }, 1000);
}

function updateChart(element, chart)
{
    const uri = '/api/v1/stats/memory';
    fetch(uri, {
        credentials: 'include',
        method: 'GET',
        headers: {
            'Accept': 'application/json'
        }
    }).then((response) => {
        if (!response.ok) {
            throw new Error('Charts: ' + response.statusText);
        }
        return response.json();
    }).then((obj) => {
        let opts = {
            stroke: {
                curve: 'smooth'
            },
            yaxis: {
                type: 'numeric',
                logBase: 8,
                labels: {
                    formatter: function(val, idx) {
                        return ((parseInt(val) / 1024 / 1024 / 1024).toFixed(1))  + "GiB";
                    }
                },
                max: obj.total,
                min: 0
            },
            series: [
                {
                    data: obj.used.map((o) => {
                        return {
                            y: o.value,
                            x: o.timestamp
                        };
                    })
                }
            ]
        };
        chart.updateOptions(opts);
        console.log(obj);
    }).catch((err) => console.log(err));
}

/**
 * Preload all charts ready for loading
 */
document.addEventListener('DOMContentLoaded', function(ev)
{
    Array.from(document.getElementsByClassName('chart')).forEach(
            (element) => {
                initialiseChartElement(element);
            }
    );
});