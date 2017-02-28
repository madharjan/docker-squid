@test "checking process: squid" {
  run docker exec squid /bin/bash -c "ps aux | grep -v grep | grep '/usr/sbin/squid3'"
  [ "$status" -eq 0 ]
}

@test "checking process: nginx (master process disabled by DISABLE_SQUID)" {
  run docker exec squid_no_squid /bin/bash -c "ps aux | grep -v grep | grep '/usr/sbin/squid3'"
  [ "$status" -eq 1 ]
}

@test "checking request: status (google via squid)" {
  run docker exec squid /bin/bash -c "curl --proxy localhost:3128 -I -s -L http://www.google.com | head -n 1 | cut -d$' ' -f2"
  [ "$status" -eq 0 ]
  [ "$output" -eq 302 ]
}

@test "checking request: content (google via squid)" {
  run docker exec squid /bin/bash -c "curl --proxy localhost:3128 -s -L http://www.google.com.sg | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 5 ]
}
