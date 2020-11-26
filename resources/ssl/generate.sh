#! /bin/sh

set -e

LOG=generate.log
rm -f $LOG serial index.txt key/ca.pem cert/ca.pem

addlog () { tee -a $LOG ; }
log    () { cat >> $LOG ; }

echo 1000 >serial
touch index.txt
for d in new crt key
do
	[ -d "$d" ] || mkdir "$d"
done

echo "Generating CA key..."                                     | addlog
openssl genrsa -passout pass: -out key/ca.pem 2048            2>&1 | log
echo

echo "Generating CA cert..."                                    | addlog
openssl req -config cnf/ca.cnf -new -x509 -days 3650 \
	-key key/ca.pem -out crt/ca.pem                           2>&1 | log
echo

for cert in alternate good wrong bad
do
	if [ -e "cnf/$cert.cnf" ]; then
		echo "Generating $cert key & certs..."                  | addlog
		rm -f $cert.csr key/$cert.pem crt/$cert.pem
		
		# Generate private key and cert request
		echo "Key + CSR..."                                     | addlog
		openssl req -config cnf/$cert.cnf -new \
			-keyout key/$cert.pem -out $cert.csr              2>&1 | log
		echo
		
		# Sign with CA cert
		echo "CRT..."                                           | addlog
		openssl ca -batch -config cnf/ca.cnf \
			-in $cert.csr -out crt/$cert.pem                  2>&1 | log
		echo
		
		# Cleanup cert request
		rm -f $cert.csr
	fi
done

echo DONE                                                       | addlog

rm -rf index.txt* serial* new
