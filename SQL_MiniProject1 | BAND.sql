-- Primero ejecuto el archivo de SQL 'create_table_bands' para crear las tablas de mi base de datos en MySQL Workbench.
-- Después ejecuto el archivo de SQL 'insert_into_bands' para introducir los datos que componen la base de datos.
-- Reviso el Modelo Entidad-Relación (claves primarias, claves externas y tipo de relaciones entre las tablas).

-- Ahora comenzaré a trabajar con mi base de datos:

-- 1. Músicos de una banda que haya publicado un álbum de rock en los años 90 con una duración mínima de 120 minutos. 

SELECT DISTINCT mn.musician_name AS musico, b.band_name AS banda, a.release_date AS publicacion, a.run_time AS duracion
FROM musician_name AS mn
JOIN musician AS m 
ON mn.musician_id = m.musician_id
JOIN band_musician AS bm 
ON m.musician_id = bm.musician_id
JOIN band AS b 
ON bm.band_id = b.band_id
JOIN album AS a 
ON b.band_id = a.band_id
JOIN band_genre AS bg 
ON b.band_id = bg.band_id
WHERE bg.genre_name LIKE '%rock%'
AND a.release_date BETWEEN '1990-01-01' AND '1999-12-31'
AND a.run_time >= 120
ORDER BY a.run_time DESC; -- ordenados de los que tienen mayor a menor duración

-- Creo una tabla temporal con estos datos para usarlos en la pregunta siguiente:

CREATE TEMPORARY TABLE 
IF NOT EXISTS bandas_rock_90 AS (SELECT DISTINCT mn.musician_name AS musico, b.band_name AS banda, 
													a.release_date AS publicacion, a.run_time AS duracion
									FROM musician_name AS mn
									JOIN musician AS m 
									ON mn.musician_id = m.musician_id
									JOIN band_musician AS bm 
									ON m.musician_id = bm.musician_id
									JOIN band AS b 
									ON bm.band_id = b.band_id
									JOIN album AS a 
									ON b.band_id = a.band_id
									JOIN band_genre AS bg 
									ON b.band_id = bg.band_id
									WHERE bg.genre_name LIKE '%rock%'
									AND a.release_date BETWEEN '1990-01-01' AND '1999-12-31'
									AND a.run_time >= 120);

-- 2. De estas mismas bandas (sin antiguos miembros) cuáles han publicado álbumes de música electrónica con ventas superiores a 5000.

SELECT DISTINCT br.banda AS banda, a.album_name AS album, a.sales_amount AS ventas
FROM bandas_rock_90 AS br
JOIN band AS b
ON br.banda = b.band_name
JOIN band_genre AS bg
ON b.band_id = bg.band_id
JOIN album AS a
ON b.band_id = a.band_id
JOIN band_musician AS bm
ON b.band_id = bm.band_id
WHERE bg.genre_name LIKE '%electronic%'
AND a.sales_amount > 5000
AND bm.musician_status != 'former';

-- 3. TOP 5 de bandas con la mayor cantidad de álbumes publicados (nombre de la banda y número de álbumes).

SELECT b.band_name AS banda, COUNT(DISTINCT a.album_name) AS albumes_publicados
FROM band AS b
JOIN album AS a
ON b.band_id = a.band_id
GROUP BY 1 
ORDER BY 2 DESC
LIMIT 5;

-- 4. Nombres de músicos del genero 'Nu metal'(y las bandas a las que pertenecían) que ya no pertenecen a ninguna banda.

SELECT DISTINCT mn.musician_name AS musico, b.band_name AS banda
FROM musician_name AS mn
JOIN musician AS m
ON mn.musician_id = m.musician_id
JOIN band_musician AS bm
ON m.musician_id = bm.musician_id
JOIN band AS b
ON bm.band_id = b.band_id
JOIN band_genre AS bg
ON b.band_id = bg.band_id
WHERE bm.musician_status = 'former'
AND bg.genre_name = 'Nu metal';

-- 5. Género musical más popular (del que más albumes hay) y cantidad de bandas que pertenecen a ese genero. 

SELECT bg.genre_name AS genero_mas_popular, COUNT(DISTINCT a.album_id) AS numero_de_albumes
FROM band_genre AS bg
JOIN band as b
ON bg.band_id = b.band_id
JOIN album AS a
ON b.band_id = a.band_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 6. De la pregunta anterior, TOP 3 de las bandas que hayan sacado más albumes de ese género musical.

SELECT DISTINCT b.band_name AS banda, COUNT(DISTINCT a.album_name) AS numero_de_albumes
FROM band as b
JOIN album AS a
ON b.band_id = a.band_id
JOIN band_genre AS bg
ON b.band_id = bg.band_id
WHERE bg.genre_name = 'Alternative rock'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- 7. Mostrar los músicos que han participado en bandas que han lanzado más de 200 álbumes.

SELECT DISTINCT mn.musician_name AS musico, b.band_name AS banda, COUNT(DISTINCT a.album_name) AS albumes
FROM musician_name AS mn
JOIN musician AS m
ON mn.musician_id = m.musician_id
JOIN band_musician AS bm
ON m.musician_id = bm.musician_id
JOIN band AS b
ON bm.band_id = b.band_id
JOIN band_genre AS bg
ON b.band_id = bg.band_id 
JOIN album AS a
ON b.band_id = a.band_id
GROUP BY 1, 2
HAVING albumes > 100
ORDER BY 3 DESC;

-- 8. Obtener el TOP 10 de álbumes más vendidos: nombre de la banda, álbum y ventas.

SELECT DISTINCT a.album_name AS album, b.band_name AS banda, a.sales_amount AS ventas
FROM album as a
JOIN band as b
ON a.band_id = b.band_id
ORDER BY ventas DESC
LIMIT 10;

-- 9. Bandas que pertenecen a más de 5 géneros musicales:

SELECT b.band_name AS banda, GROUP_CONCAT(bg.genre_name SEPARATOR ', ') AS genero
FROM band_genre AS bg
JOIN band as b
ON bg.band_id = b.band_id
WHERE b.band_name IN (SELECT b.band_name AS bn
						FROM band AS b
						JOIN band_genre AS bg
                        ON b.band_id = bg.band_id
						GROUP BY 1
						HAVING COUNT(bg.genre_name) > 5)
GROUP BY 1;

-- 10. Nombres de las bandas que que no han perdido integrantes desde sus inicios y cantidad de integrantes.

SELECT b.band_name AS banda, COUNT(DISTINCT bm.musician_id) AS integrantes
FROM band AS b
JOIN band_musician as bm
ON b.band_id = bm.band_id
WHERE b.band_id NOT IN (SELECT bm.band_id
						FROM band_musician as bm
                        WHERE bm.musician_status = 'former')
GROUP BY 1;

-- 11. Músicos que participan en más de una banda y mostrar los nombres de las bandas en las que participan.

SELECT mn.musician_name AS musico, GROUP_CONCAT(b.band_name SEPARATOR ', ') AS banda
FROM musician_name AS mn
JOIN musician AS m
ON mn.musician_id = m.musician_id
JOIN band_musician AS bm
ON m.musician_id = bm.musician_id
JOIN band AS b
ON bm.band_id = b.band_id
GROUP BY 1
HAVING COUNT(DISTINCT b.band_id) > 1;

-- 12. Album con el tiempo total de reproduccion (run_time) más largo y banda al que pertenece:

SELECT a.album_name AS album, b.band_name AS banda, a.run_time AS tiempo_reproduccion
FROM album AS a
JOIN band AS b
ON a.band_id = b.band_id
WHERE a.run_time = (SELECT MAX(a.run_time)
					FROM album AS a);

-- 13. Musicos cuyo nombre es 'Adam' y cantan 'pop'.

SELECT DISTINCT mn.musician_name AS musico, b.band_name AS banda
FROM musician_name AS mn
JOIN musician AS m
ON mn.musician_id = m.musician_id
JOIN band_musician AS bm
ON m.musician_id = bm.musician_id
JOIN band AS b
ON bm.band_id = b.band_id
JOIN band_genre AS bg
ON b.band_id = bg.band_id
WHERE mn.musician_name LIKE 'Adam%'
AND bg.genre_name LIKE '%Pop%';

-- 14. Grupo de 'Dance-Pop' con mas integrantes en sus inicios (aunque ahora ya no estén todos).

SELECT b.band_name AS banda, COUNT(DISTINCT bm.musician_id) AS integrantes
FROM band AS b
JOIN band_musician AS bm
ON b.band_id = bm.band_id
JOIN band_genre AS bg
ON b.band_id = bg.band_id
WHERE bg.genre_name = 'Dance-Pop'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;



