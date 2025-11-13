<?php
require_once('ReportGenerator.php');

session_start();

$reportGenerator = new ReportGenerator();

// Get report parameters from request
$reportType = $_GET['type'] ?? 'collection';
$startDate = $_GET['start_date'] ?? date('Y-m-d', strtotime('-30 days'));
$endDate = $_GET['end_date'] ?? date('Y-m-d');
$format = $_GET['format'] ?? 'pdf';
$category = $_GET['category'] ?? null;

// Generate report based on type
$reportData = [];
switch($reportType) {
    case 'collection':
        $reportData = $reportGenerator->generateCollectionReport($startDate, $endDate, $category);
        break;
    case 'expense':
        $reportData = $reportGenerator->generateExpenseReport($startDate, $endDate, $category);
        break;
    case 'pending':
        $reportData = $reportGenerator->generatePendingFeesReport($category);
        break;
    case 'deposit':
        $reportData = $reportGenerator->generateDepositReport($category);
        break;
    default:
        header('HTTP/1.1 400 Bad Request');
        echo json_encode(['error' => 'Invalid report type']);
        exit();
}

// Export report in requested format
try {
    $exportResult = $reportGenerator->exportReport($reportData, $format);
    if ($exportResult['success']) {
        header('Content-Type: application/json');
        echo json_encode([
            'success' => true,
            'file_url' => $exportResult['file_path'],
            'report_data' => $reportData
        ]);
    } else {
        throw new Exception('Failed to export report');
    }
} catch (Exception $e) {
    header('HTTP/1.1 500 Internal Server Error');
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>