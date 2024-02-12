
disable_mlock = true

controller {
  name = "docker-controller"
  description = "A controller for a docker demo!"
  database {
      url = "env://BOUNDARY_PG_URL"
  }
  //public_cluster_addr = "env://HOSTNAME"
  //public_cluster_addr = "boundary.signature-it.com"
}

worker {
  name = "docker-worker"
  description = "A worker for a docker demo"
  // public address 127 because we're portforwarding the connection from docker to host machine.
  // So for the client running in host machine, the connection ip is 127
  // If you're using this in a remote server, then the ip should be changed to machine public address, so that your local machine can communicate to this worker.
  public_addr = "127.0.0.1"
}

listener "tcp" {
  //address = "boundary"
  address = "0.0.0.0:9200"
  purpose = "api"
  //tls_disable = true
  //tls_cert_file = "/boundary/host.crt"
  //tls_key_file  = "/boundary/host.key"
  //tls_min_version = "tls13"
}

listener "tcp" {
  address = "boundary"
  purpose = "cluster"
  tls_disable = true
}

listener "tcp" {
  address = "boundary"
  purpose = "proxy"
  tls_disable = true
}

// Yoy can generate the keys by
// `python3 kyegen.py`
// Ref: https://www.boundaryproject.io/docs/configuration/kms/aead
kms "aead" {
  purpose = "root"
  aead_type = "aes-gcm"
  key = "wo0YIch+vySVZKdKiDHOBg2TsMXYMXF3knmAf4bOlEA="
  key_id = "global_root"
}

kms "aead" {
  purpose = "worker-auth"
  aead_type = "aes-gcm"
  key = "IK5wYBfTKbYueB6GLbueHfG0BNW2fOt6MAxTFJ0MGMk="
  key_id = "global_worker-auth"
}

kms "aead" {
  purpose = "recovery"
  aead_type = "aes-gcm"
  key = "WiyN4nuh/K+TrvPv76tFbRHjuX5zqeDYGLOTpOscU0I="
  key_id = "global_recovery"
}

