<?php

/*
  This file is our main PHP API implementation with GET/POST handling from our clients, it in turns reaches to our backend APIs (could also be databases, etc..).
  Currently it is written to interact with the nodejs-graphql in the same directory, a NodeSJ GraphQL implementation that talks to a database backend.
*/

require_once('../model/response.php');
require('../model/validator.php');

$lb_internal = getenv('LB_INTERNAL');
$hostname = gethostname();
$ip = $_SERVER['SERVER_ADDR'];

if(empty($lb_internal)) {
  $response = new Response();
  $response->setHttpStatusCode(500);
  $response->setSuccess(false);
  $response->addMessage("Backend API hostname or IP address was not provided.");
  $response->send();
  exit;
}

if($_SERVER['REQUEST_METHOD'] === 'GET') {

    $backend_url = 'http://' . $lb_internal .
        '/api/bank' .
        '?operationName=read&query=' . urlencode('query read {
          read_database{
            id
            balance
            transactiontime
          }
          read_transaction(hostname:"' . $hostname . '", ip:"' . $ip . '") {
            id
            database_server
            backend_server
            backend_ip
            frontend_server
            frontend_ip
          }
        }');

    $header = array(
      "Content-Type: application/x-www-form-urlencoded",
    );
    $options = array(
      'http' => array(
        'method' => 'POST',
        'header' => implode("\r\n", $header),
        'timeout' => 15,  //15 Seconds
      )
    );

    $backend_json = file_get_contents($backend_url, false, stream_context_create($options));

    $backend_array = json_decode($backend_json, true);

    if (!empty($backend_array)) {
      foreach ($backend_array['data']['read_transaction'] as $key => $item) {
        $database = $item['database_server'];
        $backend = $item['backend_server'];
        $backendIP = $item['backend_ip'];
        $frontend = $item['frontend_server'];
        $frontendIP = $item['frontend_ip'];
      }
      foreach ($backend_array['data']['read_database'] as $key => $item) {
        $balance = new Balance($item['balance'], $item['id'], $database, $frontend, $frontendIP, $backend, $backendIP);
        $returnData[] = $balance->returnBalanceAsArray();
      }
      $response = new Response();
      $response->setHttpStatusCode(200);
      $response->setSuccess(true);
      $response->setData($returnData);
      $response->send();
      exit;
    }

    $response = new Response();
    $response->setHttpStatusCode(500);
    $response->setSuccess(false);
    $response->addMessage("Error in interacting with backend API service on " . $lb_internal . ".");
    $response->send();
    exit;
  }
elseif($_SERVER['REQUEST_METHOD'] === 'POST') {
  if (!empty($_POST['balance'])) {
    $postbalance = $_POST['balance'];

    if(!is_numeric($postbalance)) {
      $response = new Response();
      $response->setHttpStatusCode(400);
      $response->setSuccess(false);
      $response->addMessage("Balance must be numeric.");
      $response->send();
      exit;
    }

    try {
      $newBalance = new Balance($postbalance, null, "null", $hostname, "null", "null", "null");

      $balance = $newBalance->getBalance();

      $backend_url = 'http://' . $lb_internal .
          '/api/bank' .
          '?operationName=add&query=' . urlencode('mutation add {
            add(balance: ' . $balance . ', item_content: "This line is added by frontend application.") {
              status
            }
          }');

      $header = array(
        "Content-Type: application/x-www-form-urlencoded"
      );

      $options = array(
        'http' => array(
          'method' => 'POST',
          'header' => implode("\r\n", $header),
          'timeout' => 15,  //15 Seconds
        )
      );

      $backend_json = file_get_contents($backend_url, false, stream_context_create($options));
      $backend_array = json_decode($backend_json, true);

      if (!empty($backend_array)) {
        $response = new Response();
        $response->setHttpStatusCode(200);
        $response->setSuccess(true);
        $response->setData($backend_array['data']['add'] );
        $response->send();
        exit;
      }

      $response = new Response();
      $response->setHttpStatusCode(500);
      $response->setSuccess(false);
      $response->addMessage("Error in interacting with backend API service on " . $lb_internal . ".");
      $response->send();
      exit;
    }
    catch(BalanceException $ex) {
      $response = new Response();
      $response->setHttpStatusCode(400);
      $response->setSuccess(false);
      $response->addMessage($ex->getMessage());
      $response->send();
      exit;
    }
  }
  else {
    $response = new Response();
    $response->setHttpStatusCode(400);
    $response->setSuccess(false);
    $response->addMessage("Balance value must be provided.");
    $response->send();
    exit;
  }
}
else {
  $response = new Response();
  $response->setHttpStatusCode(405);
  $response->setSuccess(false);
  $response->addMessage("Request method not allowed.");
  $response->send();
  exit;
}
?>