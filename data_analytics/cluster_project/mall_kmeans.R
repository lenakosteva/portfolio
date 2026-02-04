# Установка и загрузка необходимых пакетов
install.packages(c("factoextra", "ggplot2", "dplyr"))
library(factoextra)
library(ggplot2)
library(dplyr)

# Шаг 1. Загрузка данных
setwd("C:/Users/ElenaKosteva/Elena/СПБГУ/3 курс/6 семестр/Бизнес-анализ информации/проект_кластаризация/")
mall_data <- read.csv("Mall_Customers.csv", header = TRUE)

# Просмотр структуры данных
str(mall_data)
summary(mall_data)

# Шаг 2. Подготовка данных
# Удаляем ID клиента (не информативно для анализа)
mall_data <- mall_data %>% select(-CustomerID)

# Преобразуем Gender в числовой формат (Female=1, Male=0)
mall_data$Gender <- ifelse(mall_data$Gender == "Female", 1, 0)

# Проверяем на пропущенные значения
sum(is.na(mall_data))

# Шаг 3. Стандартизация данных
mall_scaled <- scale(mall_data, center = TRUE, scale = TRUE)

# Шаг 4. Определение оптимального числа кластеров (Elbow method)
set.seed(123) # для воспроизводимости
fviz_nbclust(mall_scaled, kmeans, method = "wss") +
  geom_vline(xintercept = 5, linetype = 2) +
  labs(subtitle = "Elbow method")

# Шаг 5. Кластерный анализ k-means (выбираем 5 кластеров)
kmeans_result <- kmeans(mall_scaled, centers = 5, nstart = 25, iter.max = 100)

# Просмотр результатов
print(kmeans_result)

# Шаг 6. Анализ результатов
# Размеры кластеров
kmeans_result$size

# Центры кластеров (транспонированная матрица для удобства)
t(round(kmeans_result$centers, 2))

# Визуализация кластеров
fviz_cluster(kmeans_result, data = mall_scaled,
             geom = "point",
           #  ellipse.type = "norm",
             main = "Кластеры посетителей торгового центра")

# Шаг 7. Интерпретация кластеров
# Добавляем информацию о кластерах к исходным данным
mall_data$Cluster <- as.factor(kmeans_result$cluster)

# Средние значения по кластерам
cluster_means <- mall_data %>%
  group_by(Cluster) %>%
  summarise_all(mean)

print(cluster_means)

# Шаг 8. Детальная визуализация
# 1. Распределение возраста по кластерам
ggplot(mall_data, aes(x = Cluster, y = Age, fill = Cluster)) +
  geom_boxplot() +
  labs(title = "Распределение возраста по кластерам",
       x = "Кластер", y = "Возраст")

# 2. Распределение дохода и расходов по кластерам
ggplot(mall_data, aes(x = Annual.Income..k.., 
                      y = Spending.Score..1.100., 
                      color = Cluster)) +
  geom_point(size = 3) +
  labs(title = "Доход vs Расходы по кластерам",
       x = "Годовой доход (тыс. $)", 
       y = "Оценка расходов (1-100)")

# 3. PCA-анализ для визуализации
pca_result <- prcomp(mall_scaled, center = TRUE, scale. = TRUE)
fviz_pca_ind(pca_result,
             col.ind = as.factor(kmeans_result$cluster),
             addEllipses = TRUE,
             legend.title = "Кластеры",
             title = "PCA визуализация кластеров")

