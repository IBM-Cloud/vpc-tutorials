#!/usr/bin/env python3
from fabric import Connection
import paramiko
import time
import socket
import procin
import functools
from pathlib import Path
from contextlib import contextmanager


onprem = "52.118.144.0"
user = "root"
sleep_time = 5.0
ssh_connect_time = float(10 * 60)

class Cache:
  @functools.lru_cache()
  def __init__(self):
    dir = str(Path(__file__).parent / "..")
    c = procin.Command(json=True)
    tfout = c.run(["terraform", "output", f"-state={dir}/terraform.tfstate", "-json"])
    for output, output_typed_value in tfout.items():
      value = output_typed_value['value']
      setattr(self, output, value)

global_cache = Cache()

def does_host_have_ssh(hostname, username):
  "try for a while then raise an exception if it is not possible to ssh"
  with paramiko.SSHClient() as client:
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.client.AutoAddPolicy)
    now = time.time()
    end = now + ssh_connect_time
    while now < end:
      try:
        client.connect(hostname, username=username, timeout=5)
        break
      except Exception as e:
        print(e)
        time.sleep(sleep_time)
    else:
      raise Exception("Timeout")

def test_connection_ip_fip_onprem():
  fip = global_cache.ip_fip_onprem
  does_host_have_ssh(fip, user)
  with Connection(fip, user) as c:
   c.open()
   ret = c.run("/bin/hostname", in_stream=False)
   assert "onprem" in ret.stdout

def test_connection_ip_fip_bastion():
  fip = global_cache.ip_fip_bastion
  does_host_have_ssh(fip, user)
  with Connection(fip, user) as c:
   c.open()
   ret = c.run("/bin/hostname", in_stream=False)
   assert "bastion" in ret.stdout

@contextmanager
def connection_ip_fip_bastion_to_ip_private_cloud() -> Connection:
  bastion = global_cache.ip_fip_bastion
  cloud = global_cache.ip_private_cloud
  ret = None
  with Connection(bastion, user) as b:
   b.open()
   yield Connection(cloud, user, gateway=b)

# todo add polling to access private cloud in case it is taking some time to initialize
def test_connection_ip_fip_bastion_to_ip_private_cloud():
  with connection_ip_fip_bastion_to_ip_private_cloud() as c:
    ret = c.run("/bin/hostname", in_stream=False)
    assert ret.stdout.endswith("-cloud\n")

def test_connection_ip_fip_onprem_to_ip_private_bastion_to_ip_private_cloud():
  onprem = global_cache.ip_fip_onprem
  bastion = global_cache.ip_private_bastion
  cloud = global_cache.ip_private_cloud
  with Connection(onprem, user) as onprem_connection:
   onprem_connection.open()
   with Connection(bastion, user, gateway=onprem_connection) as bastion_connection:
     bastion_connection.open()
     with Connection(cloud, user, gateway=bastion_connection) as onprem_connection:
        onprem_connection.open()
        ret = onprem_connection.run("/bin/hostname", in_stream=False)
        assert ret.stdout.endswith("-cloud\n")

@contextmanager
def connection_ip_fip_onprem() -> Connection:
  fip = global_cache.ip_fip_onprem
  with Connection(fip, user) as c:
   yield c

def test_dns_bastion():
  with connection_ip_fip_bastion_to_ip_private_cloud() as c:
    ret = c.run(f"/usr/bin/dig +short {global_cache.hostname_postgresql}", in_stream=False)
    assert global_cache.ip_endpoint_gateway_postgresql == ret.stdout.strip()
    ret = c.run(f"/usr/bin/dig +short {global_cache.hostname_cos}", in_stream=False)
    assert global_cache.ip_endpoint_gateway_cos == ret.stdout.strip()

def test_dns():
  with connection_ip_fip_onprem() as c:
    ret = c.run(f"/usr/bin/dig +short {global_cache.hostname_postgresql}", in_stream=False)
    assert global_cache.ip_endpoint_gateway_postgresql == ret.stdout.strip()
    ret = c.run(f"/usr/bin/dig +short {global_cache.hostname_cos}", in_stream=False)
    assert global_cache.ip_endpoint_gateway_cos == ret.stdout.strip()

if __name__ == "__main__":
  print(f"onprem = {global_cache.ip_fip_onprem}")
  print(f"bastion = {global_cache.ip_fip_bastion}")
  print(f"cloud = {global_cache.ip_private_cloud}")

