# Установка и загрузка необходимых пакетов
install.packages(c("dbscan", "ggplot2", "dplyr", "factoextra"))
library(dbscan)
library(ggplot2)
library(dplyr)
library(factoextra)

# Шаг 1. Загрузка и подготовка данных
setwd("C:/Users/ElenaKosteva/Elena/СПБГУ/3 курс/6 семестр/Бизнес-анализ информации/проект_кластаризация/")
mall_data <- read.csv("Mall_Customers.csv", header = TRUE)

# Удаляем ID клиента и преобразуем Gender в числовой формат
mall_data <- mall_data %>%
  select(-CustomerID) %>%
  mutate(Gender = ifelse(Gender == "Female", 1, 0))

# Стандартизация данных (важно для DBSCAN)
mall_scaled <- scale(mall_data)

# Шаг 2. Определение оптимальных параметров DBSCAN

# Метод k-расстояний для подбора eps
kNNdistplot(mall_scaled, k = 5)
abline(h = 0.4, col = "red", lty = 2) # Примерное значение для eps

# Шаг 3. Применение DBSCAN с выбранными параметрами
set.seed(123)
dbscan_result <- dbscan(mall_scaled, 
                        eps = 0.86,   # радиус окрестности
                        minPts = 5)  # минимальное количество точек в окрестности

# Просмотр результатов
print(dbscan_result)

# Шаг 4. Анализ результатов кластеризации

# Количество кластеров (исключая шум, который обозначен как 0)
n_clusters <- length(unique(dbscan_result$cluster)) - 1
cat("Найдено кластеров:", n_clusters, "\n")

# Размеры кластеров
table(dbscan_result$cluster)

# Добавляем информацию о кластерах к данным
mall_data$Cluster <- as.factor(dbscan_result$cluster)

# Шаг 5. Визуализация результатов

# 1. Визуализация в пространстве доход-расходы
ggplot(mall_data, aes(x = Annual.Income..k.., 
                      y = Spending.Score..1.100.,
                      color = Cluster)) +
  geom_point(size = 3) +
  labs(title = "DBSCAN: Кластеризация по доходу и расходам",
       x = "Годовой доход (тыс. $)",
       y = "Оценка расходов (1-100)") +
  scale_color_discrete(name = "Кластер")

# 2. Визуализация в пространстве возраст-расходы
ggplot(mall_data, aes(x = Age, 
                      y = Spending.Score..1.100.,
                      color = Cluster)) +
  geom_point(size = 3) +
  labs(title = "DBSCAN: Кластеризация по возрасту и расходам",
       x = "Возраст",
       y = "Оценка расходов (1-100)")

# 3. PCA-визуализация для многомерного представления
fviz_cluster(dbscan_result, 
             data = mall_scaled,
             geom = "point",
             main = "DBSCAN кластеризация (PCA визуализация)")
# Шаг 6. Анализ характеристик кластеров
cluster_profile <- mall_data %>%
  filter(Cluster != "0") %>% # Исключаем шумовые точки
  group_by(Cluster) %>%
  summarise(
    Count = n(),
    Avg_Age = round(mean(Age), 1),
    Avg_Income = round(mean(Annual.Income..k..), 1),
    Avg_Spending = round(mean(Spending.Score..1.100.), 1),
    Gender_Ratio = round(mean(Gender), 2)
  )
print(cluster_profile)    
    