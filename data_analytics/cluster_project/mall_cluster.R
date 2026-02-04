# Установка и загрузка необходимых пackages
install.packages(c("factoextra", "igraph", "dplyr"))
library(factoextra)
library(igraph)
library(dplyr)

# Шаг 1. Загрузка данных
# Предполагаем, что файл скачан и находится в рабочей директории
setwd("C:/Users/ElenaKosteva/Elena/СПБГУ/3 курс/6 семестр/Бизнес-анализ информации/проект_кластеризация/")
mall_data <- read.csv("Mall_Customers.csv", header = TRUE)

# Просмотр структуры данных
str(mall_data)
summary(mall_data)

# Шаг 2. Подготовка данных
# Удаляем ненужные столбцы (CustomerID не нужен для кластеризации)
mall_data <- mall_data %>% select(-CustomerID)

# Преобразуем Gender в числовой формат (Female=1, Male=0)
mall_data$Gender <- ifelse(mall_data$Gender == "Female", 1, 0)
summary(mall_data)
# Проверяем на пропущенные значения
sum(is.na(mall_data))

# Шаг 3. Стандартизация данных
mall_scaled <- scale(mall_data, center = TRUE, scale = TRUE)
summary(mall_scaled)

# Шаг 4. Вычисление матрицы расстояний
d <- dist(mall_scaled, method = "euclidean")

# Шаг 5. Иерархическая кластеризация
# Пробуем разные методы связывания
clust_ward <- hclust(d, method = "ward.D2")
clust_complete <- hclust(d, method = "complete")
clust_average <- hclust(d, method = "average")

# Шаг 6. Визуализация дендрограмм
par(mfrow = c(1, 3))
plot(clust_ward, main = "Ward Method")
plot(clust_complete, main = "Complete Linkage", hang = -1)
plot(clust_average, main = "Average Linkage", hang = -1)
par(mfrow = c(1, 1))


# Шаг 7. Определение оптимального числа кластеров
# Метод локтя (Elbow Method)
fviz_nbclust(mall_scaled, FUN = hcut, method = "wss")

# Шаг 8. Вырезаем кластеры (выберем 5 кластеров)
groups <- cutree(clust_ward, k = 5)

# Добавляем информацию о кластерах к исходным данным
mall_data$Cluster <- as.factor(groups)

# Шаг 9. Анализ характеристик кластеров
# Средние значения по кластерам
cluster_means <- mall_data %>%
  group_by(Cluster) %>%
  summarise_all(mean)

print(cluster_means)

# Визуализация кластеров
# По возрасту и доходу
fviz_cluster(list(data = mall_scaled, cluster = groups),
             choose.vars = c("Age", "Annual.Income..k.."),
             geom = "point",
             stand = FALSE,
             ellipse.type = "norm")

# По доходу и Spending Score
fviz_cluster(list(data = mall_scaled, cluster = groups),
             choose.vars = c("Annual.Income..k..", "Spending.Score..1.100."),
             geom = "point",
             stand = FALSE,
             ellipse.type = "norm")

# Шаг 10. Подробная визуализация дендрограммы
fviz_dend(clust_ward, k = 5,
          color_labels_by_k = TRUE,
          rect = TRUE,
          rect_fill = TRUE,
          type = "rectangle",
          main = "Дендрограмма (метод Уорда)")

