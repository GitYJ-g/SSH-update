#!/bin/bash
installZlib(){
  [ -d zlib-1.3.1 ] && echo "zlib-1.3.1 has exsited! deleted this " && rm -rf zlib-1.3.1
  tar -zxvf zlib-1.3.1.tar.gz 
  cd zlib-1.3.1/
  ./configure --prefix=/usr/local/zlib
  make -j 4 && make test && make install
  [ $? -gt 0 ] && echo "zlib made failed......" && exit 1
  echo "zlib made successfully"
  rm -rf ./zlib-1.3.1 && echo "delete dir zlib-1.3.1" 
}
installOpenSSL(){
  cd ..
  [-d openssl-1.1w ] && echo "delete this dir openssl-1.1w" && rm -rf openssl-1.1w
  tar -zxvf openssl-1.1.1w.tar.gz
  cd openssl-1.1.1w/
  mv /usr/bin/openssl /usr/bin/openssl.old
  mv /usr/include/openssl /usr/include/openssl.old
  ./config --prefix=/usr/local/openssl
  make && make install
  [ $? -gt 0 ] && echo "openssl made failed....." && exit 1
  ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl
  ln -s /usr/local/openssl/include/openssl /usr/include/openssl
  echo "/usr/local/openssl/lib" >> /etc/ld.so.conf
  ldconfig -v
  openssl version && $? -eq 0 && echo "openssl updates successfully"
  rm -rf ./openssl-1.1w && echo "delete dir openssl-1.1w"
}
installOpenSSH(){
  cd ..
  [-d "./openssh-9.8p1" ] && echo "delete this dir openssh-9.8p1" && rm -rf ./openssh-9.8p1
  tar -zxvf openssh-9.8p1.tar.gz
  cd openssh-9.8p1/
  ln -sf /usr/local/openssl/lib/libssl.so.1.1 /usr/lib64/libssl.so.1.1
  ln -sf /usr/local/openssl/lib/libcrypto.so.1.1 /usr/lib64/libcrypto.so.1.1
  rpm -e `rpm -qa | grep openssh` --nodeps
   ./configure --prefix=/usr --sysconfdir=/etc/ssh --with-md5-passwords --with-pam --with-tcp-wrappers --with-ssl-dir=/usr/local/openssl --with-zlib=/usr/local/zlib --without-hardening
  [ $? -gt 0 ] && echo "ssh configure failed......." && exit 1;
  make && make install
  [ $? -gt 0 ] && echo "ssh made failed......." && exit 1;
  #vim /etc/ssh/sshd_config     //检查PermitRootLogin 和UseDNS的值
  [ -z "`sed -n '/^PermitRootLogin yes$/p' /etc/ssh/sshd_config`" ] && sed -i '$d PermitRootLogin yes' /etc/ssh/sshd_config
  [ -z "`sed -n '/^UseDNS no$/p' /etc/ssh/sshd_config`" ] && sed -i '$d UseDNS no' /etc/ssh/sshd_config
  cp -a contrib/redhat/sshd.init /etc/init.d/sshd
  cp -a contrib/redhat/sshd.pam /etc/pam.d/sshd.pam
  chmod +x /etc/init.d/sshd
  chkconfig --add sshd
  systemctl enable sshd
  chkconfig sshd on
  mv /usr/lib/systemd/system/sshd.service /tmp
  chmod 600 /etc/ssh/ssh_host_ecdsa_key
  chmod 600 /etc/ssh/ssh_host_ed25519_key
  chmod 600 /etc/ssh/ssh_host_rsa_key
  sed -i 's/GSSAPIAuthentication/#GSSAPIAuthentication/g' /etc/ssh/ssh_config
  sed -i 's/GSSAPIAuthentication/#GSSAPIAuthentication/g' /etc/ssh/sshd_config
  systemctl daemon-reload
  systemctl restart sshd
  ssh -V $? -eq 0 && echo "openssh updates successfully"
  rm -rf ./openssh-9.8p1 && echo "delete dir openssh-9.8p1"
}
installZlib
installOpenSSL
installOpenSSH
