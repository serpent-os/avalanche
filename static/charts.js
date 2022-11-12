function initialiseChartElement(element)
{
    var options = {
        chart: {
            type: 'pie',
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
            }
        },
        series: [],
        noData: {
            text: 'Loading graph'
        },
    };
    var chart = new ApexCharts(element, options);
    chart.render();
    
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