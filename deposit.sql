DELETE
FROM depo_prod
WHERE depo_prod_tp != 'DO001';

SELECT rt_id
FROM rate_rule
WHERE rt_tp = 'RT001';

DELETE
FROM prod_rate;
SELECT COUNT(1)
FROM prod_rate
GROUP BY prod_id;

# 우대금리 계산
SELECT p.prod_id,
       SUM(r.rt_pct) AS total_pref_rate
FROM rate_rule r
         JOIN prod_rate p
              ON p.prod_rt_id = r.rt_id
WHERE p.prod_id = 400
  AND p.prod_tp = 'RT006'
GROUP BY p.prod_id;