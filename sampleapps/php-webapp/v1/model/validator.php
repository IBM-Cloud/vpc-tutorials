<?php
/*
  This class is used to validate the input/output to our PHP API. It throws exception when errors are found, thus a try/catch is recommended when calling.
*/

class BalanceException extends Exception { }

class Balance {
  private $_balance;
  private $_id;

  public function __construct($balance, $id) {
    $this->setBalance($balance);
    $this->setID($id);
  }

  public function getBalance() {
    return $this->_balance;
  }

  public function getID() {
    return $this->_id;
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

  public function returnBalanceAsArray() {
    $balance = array();
    $balance['balance'] = $this->getBalance();
    $balance['id'] = $this->getID();
    return $balance;
  }
}

?>