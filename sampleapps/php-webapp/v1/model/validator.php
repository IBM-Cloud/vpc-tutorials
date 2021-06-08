<?php
/*
  This class is used to validate the input/output to our PHP API. It throws exception when errors are found, thus a try/catch is recommended when calling.
*/

class BalanceException extends Exception { }

class Balance {
  private $_balance;
  private $_id;
  private $_database;
  private $_frontend;
  private $_frontendip;
  private $_backend;
  private $_backendip;

  public function __construct($balance, $id, $database, $frontend, $frontendIP, $backend, $backendIP) {
    $this->setBalance($balance);
    $this->setID($id);
    $this->setDatabase($database);
    $this->setFrontend($frontend);
    $this->setFrontendIP($frontendIP);
    $this->setBackend($backend);
    $this->setBackendIP($backendIP);
  }

  public function getBalance() {
    return $this->_balance;
  }

  public function getID() {
    return $this->_id;
  }

  public function getDatabase() {
    return $this->_database;
  }

  public function getFrontend() {
    return $this->_frontend;
  }

  public function getFrontendIP() {
    return $this->_frontendip;
  }

  public function getBackend() {
    return $this->_backend;
  }

  public function getBackendIP() {
    return $this->_backendip;
  }

  public function setBalance($balance) {
    if(($balance !== null) && (!is_numeric($balance) || ($balance <= 0) || ($balance > 10000))) {
      throw new BalanceException("Balance needs to be greater than 0 and lower than 1001. Received " . $balance . ".");
    }
    $this->_balance = $balance;
  }

  public function setID($id) {
    if(($id !== null) && (strlen($id) > 255)) {
      throw new BalanceException("ID error");
    }

    $this->_id = $id;
  }

  public function setDatabase($database) {
    if($database === null) {
      throw new BalanceException("database error");
    }

    $this->_database = $database;
  }

  public function setFrontend($frontend) {
    if($frontend === null) {
      throw new BalanceException("frontend error");
    }

    $this->_frontend = $frontend;
  }

  public function setFrontendIP($frontendip) {
    if($frontendip === null) {
      throw new BalanceException("frontend ip error");
    }

    $this->_frontendip = $frontendip;
  }

  public function setBackend($backend) {
    if($backend === null) {
      throw new BalanceException("backend error");
    }

    $this->_backend = $backend;
  }

  public function setBackendIP($backendip) {
    if($backendip === null) {
      throw new BalanceException("backend ip error");
    }

    $this->_backendip = $backendip;
  }

  public function returnBalanceAsArray() {
    $balance = array();
    $balance['balance'] = $this->getBalance();
    $balance['id'] = $this->getID();
    $balance['database'] = $this->getDatabase();
    $balance['frontend'] = $this->getFrontend();
    $balance['frontendip'] = $this->getFrontendIP();
    $balance['backend'] = $this->getBackend();
    $balance['backendip'] = $this->getBackendIP();
    return $balance;
  }
}

?>