#' createCohort() will create a cohort from the following rules:
#' - All patients with exposure to rivaroxaban or warfarin between (and including) october 3, 2012 and december 31, 2014.
#' - Excluding the patients who had their first AF after index
#' - Excluding all the patients with index drug both riva and vka
#' - Excluding all patients younger than 18 years at index date.
#' - Optionally: with only the OAC naive patients.
#' Additional variables are created:
#' - SWITCHTO = Concept id of anticoagulant switched to after index date, if switched
#' - SWITCHDATE = Date of switch
#' - IS_NAIVE = A 1 indicates that the patienti is naive: no use of anticoagulant before index date
#' - RIVA_OR_VKA => 1 if Rivaroxaban is index drug, 0 if VKA is index drug.
createCohort <- function(connection, connectionDetails, cdm_schema,
                         target_schema, target_table,
                         onlyNaivePatients = TRUE){

  # Input the ids
  riva_ids <- c(40244445,40241331,40241332,40241333,40244446,40244447,40244443,40241334,40244448,40241335,40244444,40244449,40241337,40241336,40244450)
  warf_ids <- c(44663115,44556166,44562589,44621649,44643120,40163553,44557985,40163549,44547357,44581120,44611173,40163535,44604212,44605858,44645771,44678256,40163537,40163528,44580621,44579352,40163560,44560351,40163539,44549319,44561018,44611705,44578601,40163519,44611547,44587179,44663782,44674155,44618390,44607893,44644567,40163550,44549318,44655361,44679336,40163534,44674600,44586763,44662517,40163511,44653078,44599599,44643067,44632766,40163554,44632290,40163564,40163514,44610278,40093134,40163567,44642416,44627226,40163507,40093131,40163558,44552268,40163518,44559160,44670738,40121983,40163527,44571574,40163559,40163536,40121984,44604248,44647604,44667136,44616988,40163523,44645391,40163525,40163515,40163520,40163517,40163557,44604598,44556575,44631436,44644475,44657905,44630908,40163569,44667448,40163551,44635583,44622848,44622849,40163533,40163555,44547738,40163547,40163566,40163516,44626965,40163532,40163568,40163548,44667174,44612008,44579230,40163565,40093132,44617776,44631830,44601988,44647884,44662478,44603265,40163570,40163552,44574108,40163541,40163513,44545243,44551746,40163561,44563518,40163530,40093130,44560746,44622752,40163543,44605424,44614948,44650425,44570203,44617269,40163529,44583471,44676840,40163509,44605024,44622055,44611706,1310149,40163531,44665175,44665051,40163526,40163512,40163563,40163562,44677342,40163524,40163556,44556574,40163522,40163542,44674154,40163546,44672367,44595885,40163538,44607132,44578361,44643066,40163510,40163508,44658031,44589399,44611597,44562846,44548797,44602298,40163521,40163540,40093133,44616175,44546930,40163544,44563271,44548604,44587502,44550692,44656985,44569040,40163545,44637417,44625675,44626589)
  phen_ids <- c(44663115)#c(19035344,40078200,19079272,19081825)
  dabi_ids <- c(40228153,40228161,40228158,40228160,40228154,40228163,40228159,40228152,40228162,40228165,45775372,40228164)
  apix_ids <- c(43013028,43013030,43013027,43013026,43013029,43013024,43013031,43013032,43013033,43013034,43013025)

  # Additional where clause for selecting only naive patients (with 'No AOC use before index date')
  where_additional <- ""
  if (onlyNaivePatients) {
    where_additional <- "AND first_oac_date >= index_date"
  }

  sql <- loadRenderTranslateSql2("createCohort_parameterized.sql","OHDSIDeriveVariables",
                                 cdm_schema = cdm_schema,
                                 dbms = connectionDetails$dbms,
                                 target_schema = target_schema,
                                 target_table = target_table,
                                 study_start_date = '2012-10-03',
                                 study_end_date = '2014-12-31',
                                 riva_ids = paste(riva_ids,collapse=","),
                                 warf_ids = paste(warf_ids,collapse=","),
                                 phen_ids = paste(phen_ids,collapse=","),
                                 dabi_ids = paste(dabi_ids,collapse=","),
                                 apix_ids = paste(apix_ids,collapse=","),
                                 whereAdditional = where_additional
  )

  executeSql(connection, sql)
}
