SELECT `pharmacies_performance`.`agent` AS `Agent`,
       `pharmacies_performance`.`city_l1` AS `City L1`,
       `pharmacies_performance`.`region_l2` AS `Region_L2`,
       `pharmacies_performance`.`group_id` AS `Group ID`,
       `pharmacies_performance`.`pharmacy` AS `Group`,
       `pharmacies_performance`.`branch_id` AS `Branch ID`,
       `pharmacies_performance`.`branch` AS `Branch`,
    --   `pharmacies_performance`.`class` AS `Class`,
       `country_portal_providers`.`class` AS `Class`,
       `pharmacies_performance`.`VPN` AS `VPN`,
       `pharmacies_performance`.`custome_order_type` AS `Orders Type`,
      
       ## Score
       
       ( ( CASE WHEN SUM(`pharmacies_performance`.`dispatched_order`) / COUNT (DISTINCT CASE WHEN `pharmacies_performance`.`accepted_order` = 1 THEN `pharmacies_performance`.`external_order_reference` END) >= 0.85 THEN 20
                WHEN SUM(`pharmacies_performance`.`dispatched_order`) / COUNT (DISTINCT CASE WHEN `pharmacies_performance`.`accepted_order` = 1 THEN `pharmacies_performance`.`external_order_reference` END) >= 0.75 AND SUM(`pharmacies_performance`.`dispatched_order`) / COUNT (DISTINCT CASE WHEN `pharmacies_performance`.`accepted_order` = 1 THEN `pharmacies_performance`.`external_order_reference` END) < 0.85 THEN 10
           ELSE 0 
           END
         ) + 
       
         ( CASE WHEN SUM(`pharmacies_performance`.`cancelled_after_accepted`) / SUM(`pharmacies_performance`.`accepted_order`) <= 0.05 THEN 20
                WHEN SUM(`pharmacies_performance`.`cancelled_after_accepted`) / SUM(`pharmacies_performance`.`accepted_order`) <= 0.1 AND SUM(`pharmacies_performance`.`cancelled_after_accepted`) / SUM(`pharmacies_performance`.`accepted_order`) > 0.05 THEN 10
           ELSE 0
           END
         ) +
         
         ( CASE WHEN SUM(`pharmacies_performance`.`scanned_and_pending_order`) / SUM(`pharmacies_performance`.`dispatched_order`) <= 0.05 THEN 20
                WHEN SUM(`pharmacies_performance`.`scanned_and_pending_order`) / SUM(`pharmacies_performance`.`dispatched_order`) <= 0.1 AND SUM(`pharmacies_performance`.`scanned_and_pending_order`) / SUM(`pharmacies_performance`.`dispatched_order`) > 0.05 THEN 10
           ELSE 0
           END
         ) +
         
         ( CASE WHEN ( (SUM(`pharmacies_performance`.`withdrawn_order`) / COUNT(DISTINCT `pharmacies_performance`.`external_order_reference`) <= 0.05) 
                       AND (SUM(`pharmacies_performance`.`dispatched_order`) > 0 )
                       AND (SUM(`pharmacies_performance`.`accepted_order` > 0) )
                     ) THEN 20
                WHEN SUM(`pharmacies_performance`.`withdrawn_order`) / COUNT(DISTINCT `pharmacies_performance`.`external_order_reference`) <= 0.1 AND SUM(`pharmacies_performance`.`withdrawn_order`) / COUNT(DISTINCT `pharmacies_performance`.`external_order_reference`) > 0.05 THEN 10
           ELSE 0
           END
         ) +
         
         (
           ( CASE WHEN (SUM(`pharmacies_performance`.`private_order_within_sla`) / SUM(CASE WHEN `pharmacies_performance`.`custome_order_type` = 'Private' THEN `pharmacies_performance`.`dispatched_order` ELSE 0.0 END) ) >= 0.8 THEN 20 ELSE 0 END ) + 
           ( CASE WHEN (SUM(`pharmacies_performance`.`insurance_order_within_sla`) / SUM(CASE WHEN `pharmacies_performance`.`custome_order_type` = 'Insurance' THEN `pharmacies_performance`.`dispatched_order` ELSE 0.0 END) ) >= 0.8 THEN 20 ELSE 0 END )
         )

       
       ) AS `Score`,
       
       
       ## Metrics Used in Score Calculations
       ( SUM(`pharmacies_performance`.`dispatched_order`) / COUNT (DISTINCT CASE WHEN `pharmacies_performance`.`accepted_order` = 1 THEN `pharmacies_performance`.`external_order_reference` END) ) AS `Dispatch Rate`,
       SUM(`pharmacies_performance`.`cancelled_after_accepted`) AS `Total Orders Cancelled After Acceptance`,
       SUM(`pharmacies_performance`.`scanned_and_pending_order`) AS `Total 'Scanned & Pending' Orders`,
       SUM(`pharmacies_performance`.`withdrawn_order`) AS `Total Withdrawn Orders`,
       
       ( SUM(`pharmacies_performance`.`private_order_within_sla`) / SUM(CASE WHEN `pharmacies_performance`.`custome_order_type` = 'Private' THEN `pharmacies_performance`.`dispatched_order` ELSE 0.0 END )
       ) AS `% Private Orders  - SLA 90`,
       
       ( SUM(`pharmacies_performance`.`insurance_order_within_sla`) / SUM(CASE WHEN `pharmacies_performance`.`custome_order_type` = 'Insurance' THEN `pharmacies_performance`.`dispatched_order` ELSE 0.0 END )
       ) AS `% Insurance Orders  - SLA 160`,
       
       
       ## Rest of the Metrics
       
       COUNT(DISTINCT `pharmacies_performance`.`external_order_reference`) AS `Total Orders`,
       COUNT (DISTINCT CASE WHEN `pharmacies_performance`.`accepted_order` = 1 THEN `pharmacies_performance`.`external_order_reference` END) AS `Total Accepted Orders`,
       
       ((COUNT (DISTINCT CASE WHEN `pharmacies_performance`.`accepted_order` = 1 THEN `pharmacies_performance`.`external_order_reference` END)) / COUNT(DISTINCT `pharmacies_performance`.`external_order_reference`)) AS `Acceptance Rate`,
       SUM(`pharmacies_performance`.`dispatched_order`) AS `Total Dispatched Orders`,
       SUM(`pharmacies_performance`.`cancelled_after_dispatched`) AS `Total Orders Cancelled After Dispatched`,
       SUM(`pharmacies_performance`.`not_scanned`) AS `Total 'Not Scanned' Orders`,
       SUM(`pharmacies_performance`.`scanned`) AS `Total Scanned Orders`,
       SUM(`pharmacies_performance`.`delivered_order`) AS `Total Delivered Orders`,
       SUM(`pharmacies_performance`.`reported_a_problem_order`) AS `Total 'Reported A Problem' Orders`,
       AVG(`pharmacies_performance`.`time_to_accept`) AS `AVG Time To Accept`,
       AVG(`pharmacies_performance`.`time_to_dispatch`) AS `AVG Time To Dispatch`,
       AVG(`pharmacies_performance`.`time_to_deliver`) AS `AVG Time To Deliver - From Assignment`

FROM (SELECT `pharmacies_performance`.`id` AS `id`, 
             `pharmacies_performance`.`order_number` AS `order_number`, 
             `pharmacies_performance`.`external_order_reference` AS `external_order_reference`, 
             `pharmacies_performance`.`order_type` AS `order_type`, 
             `pharmacies_performance`.`custome_order_type` AS `custome_order_type`, 
             `pharmacies_performance`.`city_l1` AS `city_l1`, 
             `pharmacies_performance`.`region_l2` AS `region_l2`, 
             `pharmacies_performance`.`group_id` AS `group_id`, 
             `pharmacies_performance`.`pharmacy` AS `pharmacy`, 
             `pharmacies_performance`.`branch_id` AS `branch_id`, 
             `pharmacies_performance`.`branch` AS `branch`, 
             `pharmacies_performance`.`order_creation_date` AS `order_creation_date`, 
             `pharmacies_performance`.`order_creation_time` AS `order_creation_time`, 
             `pharmacies_performance`.`hop_creation_date` AS `hop_creation_date`, 
             `pharmacies_performance`.`hop_creation_time` AS `hop_creation_time`, 
             `pharmacies_performance`.`hop_update_date` AS `hop_update_date`, 
             `pharmacies_performance`.`hop_update_time` AS `hop_update_time`, 
             `pharmacies_performance`.`class` AS `class`, 
             `pharmacies_performance`.`VPN` AS `VPN`, 
             `pharmacies_performance`.`agent` AS `agent`, 
             `pharmacies_performance`.`accepted_order` AS `accepted_order`, 
             `pharmacies_performance`.`dispatched_order` AS `dispatched_order`,
             `pharmacies_performance`.`cancelled_after_accepted` AS `cancelled_after_accepted`,
             `pharmacies_performance`.`cancelled_after_dispatched` AS `cancelled_after_dispatched`, 
             `pharmacies_performance`.`not_scanned` AS `not_scanned`, 
             `pharmacies_performance`.`scanned` AS `scanned`, 
             `pharmacies_performance`.`delivered_order` AS `delivered_order`, 
             `pharmacies_performance`.`reported_a_problem_order` AS `reported_a_problem_order`, 
             `pharmacies_performance`.`scanned_and_pending_order` AS `scanned_and_pending_order`, 
             `pharmacies_performance`.`withdrawn_order` AS `withdrawn_order`, 
             `pharmacies_performance`.`time_to_accept` AS `time_to_accept`, 
             `pharmacies_performance`.`time_to_dispatch` AS `time_to_dispatch`, 
             `pharmacies_performance`.`time_to_deliver` AS `time_to_deliver`, 
             `pharmacies_performance`.`private_order_within_sla` AS `private_order_within_sla`,
             `pharmacies_performance`.`insurance_order_within_sla` AS `insurance_order_within_sla` 
             
      FROM `pharmacies_performance`
     ) `pharmacies_performance`
     
LEFT JOIN `country_portal_providers` ON `pharmacies_performance`.`branch_id` = `country_portal_providers`.`branch_id`

WHERE {{agent}}
      AND {{city_l1}}
      AND {{region_l2}}
      AND {{custome_order_type}}
      AND {{class}}
      AND {{VPN}}
      AND {{group_id}}
      AND {{branch_id}}
      AND {{date}}
      
GROUP BY `pharmacies_performance`.`agent`, `pharmacies_performance`.`city_l1`, `pharmacies_performance`.`region_l2`, 
         `pharmacies_performance`.`pharmacy`,  `pharmacies_performance`.`group_id`, `pharmacies_performance`.`branch_id`, 
         `pharmacies_performance`.`branch`, `pharmacies_performance`.`VPN`,
         `pharmacies_performance`.`custome_order_type`
         
ORDER BY `pharmacies_performance`.`city_l1`, `pharmacies_performance`.`region_l2`, `pharmacies_performance`.`pharmacy`





