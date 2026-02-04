import streamlit as st
import pandas as pd
import numpy as np
from bokeh.plotting import figure
import plotly.express as px

from sklearn import preprocessing
from scipy.cluster.hierarchy import linkage, fcluster
from sklearn.manifold import TSNE
from sklearn.metrics import silhouette_score
from scipy.spatial.distance import squareform
import gower

st.set_page_config(layout="wide")
st.title("BI-приложениe: Кластеризация объектов недвижимости")
st.markdown("Этот дашборд показывает результаты иерархической кластеризации объектов недвижимости с использованием метрики Gower.")

@st.cache_data
def load_data():
    df = pd.read_csv("dataset_realty_1_1.csv", sep=";", encoding='utf8', decimal=",")
    df['Цена за м2'] = round(df['Сумма договора'] / df['Площадь'], 3)
    df = df.drop(columns=[
        'Номер документа', 'Объект недвижимости', 'Основной клиент',
        'Дата брони', 'Дата рождения', 'Проект', 'Площадь', 'Сумма договора'
    ])
    return df

def plot_grouped_bar(df, category_col, hue_col, title):
    st.subheader(title)

    # Подсчет количества объектов по кластерам и категории
    counts = df.groupby(['cluster', category_col]).size().reset_index(name='Количество')
    counts.rename(columns={'cluster': 'Кластер', category_col: hue_col}, inplace=True)

    # Создание цветовой палитры в формате HSL
    num_categories = counts[hue_col].nunique()
    color_range = [f'hsl(250, 100%, {90 - i * (60 // max(1, num_categories - 1))}%)' for i in range(num_categories)]

    # Создание сгруппированной столбчатой диаграммы с Plotly Express
    fig = px.bar(
        counts,
        x='Кластер',
        y='Количество',
        color=hue_col,
        barmode='stack',  # Сгруппированные столбцы
        color_discrete_sequence=color_range,
        hover_data=['Кластер', hue_col, 'Количество']
    )

    # Настройка макета
    fig.update_layout(
        width=700,
        height=350,
        xaxis_title='Кластер',
        yaxis_title='Количество',
        legend_title=hue_col,
        showlegend=True
    )

    # Отображение графика в Streamlit
    st.plotly_chart(fig, use_container_width=True)


# загрузка данных
df = load_data()
df1 = df.copy()
scaler = preprocessing.MinMaxScaler()
df1[['Цена за м2']] = scaler.fit_transform(df[['Цена за м2']])

# кластерзация
X = np.asarray(df1)
dist_matrix = gower.gower_matrix(X)
cdist_matrix = squareform(dist_matrix)
Z = linkage(cdist_matrix, method='weighted')
df['cluster'] = fcluster(Z, t=0.56, criterion='distance')

# фильтры
with st.sidebar:
    with st.expander("Фильтры", expanded=True):
        cluster = st.multiselect(
            "Кластер",
            options=df['cluster'].unique(),
            placeholder="Выберите кластеры",
            help="Выберите один или несколько кластеров"
        )
        city = st.multiselect(
            "Город",
            options=df['Город'].unique(),
            placeholder="Выберите города",
            help="Выберите один или несколько городов"
        )
        object_type = st.multiselect(
            "Тип объекта",
            options=df['Тип объекта'].unique(),
            placeholder="Выберите типы",
            help="Выберите типы объектов"
        )
        subtype = st.multiselect(
            "Подтип",
            options=df['Подтип'].unique(),
            placeholder="Выберите подтипы",
            help="Выберите подтипы объектов"
        )
        payment = st.multiselect(
            "Вариант оплаты",
            options=df['Вариант оплаты'].unique(),
            placeholder="Выберите варианты оплаты",
            help="Выберите варианты оплаты"
        )
        status = st.multiselect(
            "Состояние",
            options=df['Состояние'].unique(),
            placeholder="Выберите состояния",
            help="Выберите состояния"
        )

filtered_df = df[
    (df['cluster'].isin(cluster if cluster else df['cluster'].unique())) &
    (df['Город'].isin(city if city else df['Город'].unique())) &
    (df['Тип объекта'].isin(object_type if object_type else df['Тип объекта'].unique())) &
    (df['Подтип'].isin(subtype if subtype else df['Подтип'].unique())) &
    (df['Вариант оплаты'].isin(payment if payment else df['Вариант оплаты'].unique())) &
    (df['Состояние'].isin(status if status else df['Состояние'].unique()))]

# обзор
st.header("Обзор кластеров")
st.subheader("Ключевые метрики")
col1, col2, col3, col4 = st.columns(4)

with col1:
    st.metric("Количество объектов", len(filtered_df))
with col2:
    st.metric("Количество кластеров", f"{filtered_df ['cluster'].nunique()}")
with col3:
    st.metric("Медианная цена за м²", f"{filtered_df['Цена за м2'].median():.2f}")
with col4:
    st.metric("Среднее отклонение цены за м²", f"{filtered_df['Цена за м2'].std():.2f}")

col5, col6 = st.columns(2)
with col5:
    # Профили кластеров
    st.subheader("Профили кластеров")
    numeric_summary = filtered_df.groupby('cluster')[['Цена за м2']].mean().round(2)

    # Моды для категориальных переменных
    categorical_summary = filtered_df.groupby('cluster')[
        ['Тип объекта', 'Подтип', 'Вариант оплаты', 'Состояние', 'Город']].agg(
        lambda x: x.mode()[0])

    # Расчет доли кластеров
    cluster_distribution = filtered_df['cluster'].value_counts(normalize=True) * 100
    cluster_distribution = cluster_distribution.round(2).reset_index()
    cluster_distribution.columns = ['cluster', 'Доля (%)']
    cluster_distribution.set_index('cluster', inplace=True)

    # Объединение всех данных
    combined_summary = pd.concat([numeric_summary, categorical_summary], axis=1)

    # Переименование столбцов для ясности (опционально)
    combined_summary.columns = [
        'Средняя цена за м²',
        'Тип объекта',
        'Подтип',
        'Вариант оплаты',
        'Состояние',
        'Город',
    ]

    # Отображение таблицы
    st.dataframe(combined_summary)


with col6:
    st.subheader("Распределение по кластерам")
    cluster_counts = filtered_df['cluster'].value_counts().sort_index()

    # Создание DataFrame для круговой диаграммы
    pie_data = pd.DataFrame({
        'Кластер': cluster_counts.index.astype(str),  # Преобразуем в строку для читаемости
        'Количество наблюдений': cluster_counts.values
    })

    # Построение круговой диаграммы
    fig = px.pie(
        pie_data,
        names='Кластер',
        values='Количество наблюдений',
        color_discrete_sequence= [f'hsl(250, 100%, {90 - i * (60 // 8)}%)' for i in range(8)],
        width=800,
        height=350
    )

    # Настройка отображения процентов и подписей
    fig.update_traces(
        textinfo='percent+label',  # Показываем проценты и метки
        textposition='outside',  # Текст внутри секторов
        rotation=90,
        hovertemplate='<b>Кластер %{label}</b><br>Количество: %{value}<br>Доля: %{percent}<extra></extra>'
    )
    fig.update_layout(
        showlegend=False,  # Отключаем легенду
    )
    # Отображение в Streamlit
    st.plotly_chart(fig, use_container_width=True)

# Характеристики кластеров
st.header("Характеристики кластеров")
col7, col8 = st.columns([3,2])
with col7:
    plot_grouped_bar(filtered_df, 'Подтип', 'Подтип', 'Распределение подтипов')
with col8:
    # Ящик с усами
    st.subheader("Цены за м² по кластерам")
    n_clusters = filtered_df['cluster'].nunique()
    fig_box = px.box(
        filtered_df,
        x='cluster',
        y='Цена за м2',
        color='cluster',
        color_discrete_sequence=[f'hsl(250, 100%, 40%)' for i in range(n_clusters)],
        hover_data=['Цена за м2']
    )
    fig_box.update_layout(
        height=400,
        xaxis_title='Кластер',
        yaxis_title='Цена за м²',
        showlegend=False
    )
    st.plotly_chart(fig_box, use_container_width=True)


col9, col10, col11 = st.columns(3)
with col9:
    plot_grouped_bar(filtered_df, 'Вариант оплаты', 'Вариант оплаты', 'Распределение вариантов оплаты')
with col10:
    plot_grouped_bar(filtered_df, 'Состояние', 'Состояние', 'Распределение состояний')
with col11:
    plot_grouped_bar(filtered_df, 'Город', 'Город', 'Распределение городов')

st.subheader("t-SNE визуализация кластеров (2D)")
tsne = TSNE(metric='precomputed', n_components=2, perplexity=35, init='random', random_state=42)
embedding = tsne.fit_transform(dist_matrix)

# Создание DataFrame
df_tsne = pd.DataFrame(embedding, columns=['x', 'y'])
df_tsne['cluster'] = df['cluster'].astype(str)

# Создание интерактивного графика
fig = px.scatter(
    df_tsne,
    x='x',
    y='y',
    color='cluster',
    color_discrete_sequence=px.colors.qualitative.Safe,
    labels={'x': 't-SNE X', 'y': 't-SNE Y', 'cluster': 'Кластер'},
    hover_name='cluster',
    width=900,
    height=600
)

fig.update_traces(marker=dict(size=7, opacity=0.7, line=dict(width=0.5, color='white')))
fig.update_layout(legend_title_text='Кластеры', legend=dict(itemsizing='constant'))

st.plotly_chart(fig, use_container_width=True)


