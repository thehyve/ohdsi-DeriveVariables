# combines read, render, translate and execute in one function
loadRenderTranslateExSql <- function(sqlFilename, dbms, connection, ...,
                                    oracleTempSchema = NULL) {

    parameterizedSql <- readSql(sqlFilename)

    renderedSql <- renderSql(parameterizedSql[1], ...)$sql

    translatedSql <- translateSql(renderedSql,
                                  targetDialect = dbms)$sql

    connection <- connect(connectionDetails)
    executeSql(connection, translatedSql)
}
