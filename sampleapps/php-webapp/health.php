<?php

/*
  This file is used to return a health response for the llad balancer.
*/

require_once('./v1/model/response.php');
require('./v1/model/validator.php');

$lb_internal = getenv('LB_INTERNAL');

if(empty($lb_internal)) {
  $response = new Response();
  $response->setHttpStatusCode(404);
  $response->setSuccess(false);
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
        }');

    $header = array(
      "Content-Type: application/x-www-form-urlencoded",
    );
    $options = array(
      'http' => array(
        'method' => 'POST',
        'header' => implode("\r\n", $header),
        'timeout' => 5,  //5 Seconds
      )
    );

    $backend_json = file_get_contents($backend_url, false, stream_context_create($options));

    $backend_array = json_decode($backend_json, true);

    if (!empty($backend_array)) {
      $response = new Response();
      $response->setHttpStatusCode(200);
      $response->setSuccess(true);
      $response->addMessage("UP");
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
else {
  $response = new Response();
  $response->setHttpStatusCode(405);
  $response->setSuccess(false);
  $response->addMessage("Request method not allowed.");
  $response->send();
  exit;
}
?>