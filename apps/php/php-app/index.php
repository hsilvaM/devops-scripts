<?php
declare(strict_types=1);

error_reporting(E_ALL);
ini_set('display_errors', '1');

$oracleUser = getenv('ORACLE_USER');
$oraclePassword = getenv('ORACLE_PASSWORD');
$oracleDsn = getenv('ORACLE_DSN');
$oracleCharset = getenv('ORACLE_CHARSET') ?: 'AL32UTF8';

if (!$oracleUser || !$oraclePassword || !$oracleDsn) {
    http_response_code(500);
    echo "<h1>Error</h1>";
    echo "<p>Faltan variables de entorno ORACLE_USER, ORACLE_PASSWORD u ORACLE_DSN.</p>";
    exit;
}

$connection = @oci_connect($oracleUser, $oraclePassword, $oracleDsn, $oracleCharset);

if (!$connection) {
    $error = oci_error();
    http_response_code(500);
    echo "<h1>No se pudo conectar a Oracle</h1>";
    echo "<pre>" . htmlspecialchars($error['message'] ?? 'Error desconocido', ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8') . "</pre>";
    exit;
}

$sql = 'SELECT SYSDATE FROM DUAL';
$statement = oci_parse($connection, $sql);

if (!$statement || !oci_execute($statement)) {
    $error = oci_error($statement);
    http_response_code(500);
    echo "<h1>Error al ejecutar la consulta</h1>";
    echo "<pre>" . htmlspecialchars($error['message'] ?? 'Error desconocido', ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8') . "</pre>";
    oci_close($connection);
    exit;
}

$row = oci_fetch_array($statement, OCI_NUM);

oci_free_statement($statement);
oci_close($connection);

echo "<h1>Conexion exitosa</h1>";
echo "<p>SYSDATE: " . htmlspecialchars($row[0] ?? 'Sin datos', ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8') . "</p>";

