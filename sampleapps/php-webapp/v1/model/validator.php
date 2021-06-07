<?php
/*
  This class is used to validate the input/output to our PHP API. It throws exception when errors are found, thus a try/catch is recommended when calling.
*/

class BalanceException extends Exception { }

class Balance {
  private $_balance;
  private $_id;
  private $_frontend;
  private $_backend;

  public function __construct($balance, $id, $frontend, $backend) {
    $this->setBalance($balance);
    $this->setID($id);
    $this->setFrontend($frontend);
    $this->setBackend($backend);
  }

  public function getBalance() {
    return $this->_balance;
  }

  public function getID() {
    return $this->_id;
  }

  public function getFrontend() {
    return $this->_frontend;
  }

  public function getBackend() {
    return $this->_backend;
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

  public function setFrontend($frontend) {
    if($frontend === null) {
      throw new BalanceException("frontend error");
    }

    $this->_frontend = $frontend;
  }

  public function setBackend($backend) {
    if($backend === null) {
      throw new BalanceException("backend error");
    }

    $this->_backend = $backend;
  }

  public function returnBalanceAsArray() {
    $balance = array();
    $balance['balance'] = $this->getBalance();
    $balance['id'] = $this->getID();
    $balance['frontend'] = $this->getFrontend();
    $balance['backend'] = $this->getBackend();
    return $balance;
  }
}

?>