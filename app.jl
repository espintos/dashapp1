using Dash, DashBootstrapComponents
using HTTP, CSV, DataFrames, JSON2

s = ["https://cdn.jsdelivr.net/gh/espintos/dash_files@1420a74936bc74542f3be223c043fd5eb3eebe3c/assets/bootstrap.css"]

app = dash(external_stylesheets=s)

read_remote_csv(url) = DataFrame(CSV.File(HTTP.get(url).body))
df = read_remote_csv("https://raw.githubusercontent.com/plotly/datasets/master/gapminderDataFiveYear.csv")

available_countries = unique(df.country)

app.layout = html_div(style=(width = "100%", textAlign="center", backgroundColor = "rgb(240, 240, 240)")) do

    dbc_row([
        dbc_col([
            html_img(
                    src="http://www.plapiqui.conicet.gov.ar/wp-content/uploads/2019/11/logo_original.png",
                    id="plapiqui-logo",
                    style=Dict("height" => "110px",),
                    )],
                align="center",width=2,
                ),

        dbc_col([
            html_div([
                html_h1("Nombre de la App",style=Dict("margin-bottom" => "0px"),),
                html_h2("Descripción 1",style=Dict("margin-bottom" => "0px"),),
                html_h3("(Descripción 2)",style=Dict("margin-bottom" => "0px"),),
                #html_a("Carrín and Crapiste (2008): Mathematical modeling of vegetable oil-solvent extraction in a multistage horizontal extractor",
                #        href="https://www.sciencedirect.com/science/article/abs/pii/S0260877407004335", target="_blank", rel="noopener noreferrer"),
                    ])
                ],id="title",width=6,
                ),

        dbc_col([
            html_img(src="https://raw.githubusercontent.com/espintos/dash_files/main/assets/logo-uns-conicet.png",
                     id="conicet-logo",
                     style=Dict("height" => "100px",),
                    ),
                ],id="conice-logo",align="center",width=2,
                ),],id="header",justify="center",
            ),

#Esto es para dejar un espacio en blanco entre el encabezado y las cajas de introducción de datos.
    html_br(),
    html_p(),

html_div(style=(width = "500px", display = "inline-block"),
[
    dcc_graph(id="clientside-graph"),
    dcc_store(
        id="clientside-figure-store",
        data=[
            Dict(
                :x => df[df.country .== "Canada", "year"],
                :y => df[df.country .== "Canada", "pop"],
            )
        ]
    ),
    "Indicator",
    dcc_dropdown(
        id="clientside-graph-indicator",
        options=[
            (label = "Population", value = "pop"),
            (label = "Life Expectancy", value = "lifeExp"),
            (label = "GDP per Capita", value = "gdpPercap"),
        ],
        value="pop",
    ),
    "Country",
    dcc_dropdown(
        id="clientside-graph-country",
        options=[
            (label = country, value = country) for country in available_countries
        ],
        value="Canada",
    ),
    "Graph scale",
    dcc_radioitems(
        id="clientside-graph-scale",
        options=[(label = x, value = x) for x in ["linear", "log"]],
        value="linear",
    ),
    ],),
    html_hr(),
    html_details([
        html_summary("Contents of figure storage"),
        dcc_markdown(id="clientside-figure-json"),
    ])
end



callback!(
    app,
    Output("clientside-figure-store", "data"),
    Input("clientside-graph-indicator", "value"),
    Input("clientside-graph-country", "value"),
) do indicator, country
    dff = df[df.country .== country, :]
    [(x = dff.year, y = dff[!, Symbol(indicator)], mode = "markers")]
end

callback!(
    """
    function(data, scale) {
        return {
            'data': data,
            'layout': {
                 'yaxis': {'type': scale}
             }
        }
    }
    """,
    app,
    Output("clientside-graph", "figure"),
    Input("clientside-figure-store", "data"),
    Input("clientside-graph-scale", "value"),
)

callback!(
    app,
    Output("clientside-figure-json", "children"),
    Input("clientside-figure-store", "data"),
) do data
    buf = IOBuffer()
    JSON2.pretty(buf, JSON2.write(data))
    js = String(take!(buf))
    """
    ```
    $(js)
    ```
    """
end

run_server(app, "0.0.0.0", debug=false)
