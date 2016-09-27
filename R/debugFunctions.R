#' Functions used for debugging only.

#' Export the drug mapping
exportDrugMapping <- function(connectionDetails, export_to) {
  query <- "SELECT vnr_mapping.*, unique_varunr.atc, unique_varunr.styrknum, unique_varunr.styrka_enh, unique_varunr.styrka_tf
            FROM etl_mappings.vnr_mapping JOIN drugmap.unique_varunr on source_concept_id = varunr;"
  connection <- connect(connectionDetails)
  result_df <- querySql(connection, query)

  write.csv(result_df, export_to)
  sprintf( "%d rows written to %s", nrow(result_df), export_to )
}
