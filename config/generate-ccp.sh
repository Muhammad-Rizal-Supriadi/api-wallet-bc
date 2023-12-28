#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local P1P=$(one_line_pem $5)
    local P2P=$(one_line_pem $6)
    local P3P=$(one_line_pem $7)
    local OP=$(one_line_pem $8)
    local CP=$(one_line_pem $9)
    sed -e "s/\${HOSTO}/$1/" \
        -e "s/\${HOSTP1}/$2/" \
        -e "s/\${HOSTP2}/$3/" \
        -e "s/\${HOSTP3}/$4/" \
        -e "s#\${PEER1PEM}#$P1P#" \
        -e "s#\${PEER2PEM}#$P2P#" \
        -e "s#\${PEER3PEM}#$P3P#" \
        -e "s#\${OPEM}#$OP#" \
        -e "s#\${CAPEM}#$CP#" \
        ./ccp-template.yaml
}

HOSTO=192.168.1.12
HOSTP1=192.168.1.48
HOSTP2=192.168.1.13
HOSTP3=192.168.1.14
HOSTCA=192.168.1.48
PEER1PEM=../../Fabric/ca/organizations/peer/kpu.zillabc.io/peers/peer1.kpu.zillabc.io/tls/tlscacerts/tls-localhost-7054-ca-kpu-zillabc-io.pem
PEER2PEM=../../Fabric/ca/organizations/peer/kpu.zillabc.io/peers/peer2.kpu.zillabc.io/tls/tlscacerts/tls-localhost-7054-ca-kpu-zillabc-io.pem
PEER3PEM=../../Fabric/ca/organizations/peer/kpu.zillabc.io/peers/peer3.kpu.zillabc.io/tls/tlscacerts/tls-localhost-7054-ca-kpu-zillabc-io.pem
OPEM=../../Fabric/ca/organizations/orderer/orderer.zillabc.io/orderers/orderer1.zillabc.io/tls/tlscacerts/tls-localhost-9054-ca-orderer-zillabc-io.pem
CAPEM=../../Fabric/ca/organizations/peer/kpu.zillabc.io/msp/tlscacerts/ca.crt

echo "$(json_ccp $HOSTO $HOSTP1 $HOSTP2 $HOSTP3 $PEER1PEM $PEER2PEM $PEER3PEM $OPEM $CAPEM )" > connection-kpu.json
echo "Connection Generated"

CHANNEL=${1}
MODE=${2}
REGION=${3}

function one_line_pem {
    echo "`awk 'NF {sub(/\\n*$/, ""); printf "%s\\\n",$0;}' $1`"
}

function many() {
    function template(){
        while read -r CHANNEL_NAME || [ -n "$CHANNEL_NAME" ]; do
            function json_ccp {
                local CP=$(one_line_pem $2)
                sed -e "s/\${CHANNEL_NAME}/$1/" \
                    -e "s#\${ISI}#$CP#" \
                    ./connection-kpu.json
            }
            ISI=./isi.txt
            echo "$(json_ccp $CHANNEL_NAME $ISI)" > connection-kpu.json
        done < "$input_file"
    }
    if [ "$REGION" == "kecamatan" ] || [ "$REGION" == "kec" ]; then
        folder_path=../../Fabric/channel/data-wilayah/kecamatan/$CHANNEL
        for input_file in "$folder_path"/*.txt; do
            # Check if the file is a regular file
            if [ -f "$input_file" ]; then
                template
            fi
        done
        echo "new connection profile for $CHANNEL is added"
    fi
    if [ "$REGION" == "kabupaten" ] || [ "$REGION" == "kab" ]; then
        input_file=../../Fabric/channel/data-wilayah/kabupaten/$CHANNEL.txt
        template
        echo "new connection profile for $CHANNEL is added"
    fi
    if [ "$REGION" == "provinsi" ] || [ "$REGION" == "prov" ]; then
        input_file=../../Fabric/channel/data-wilayah/provinsi/$CHANNEL.txt
        template
        echo "new connection profile for $CHANNEL is added"
    fi
}
function single(){
    CHANNEL_NAME=$CHANNEL
    function json_ccp {
        local CP=$(one_line_pem $2)
        sed -e "s/\${CHANNEL_NAME}/$1/" \
            -e "s#\${ISI}#$CP#" \
            ./connection-kpu.json
    }
    ISI=./isi.txt
    echo "$(json_ccp $CHANNEL_NAME $ISI)" > connection-kpu.json
    echo "new connection profile for $CHANNEL is added"
}

if [ "$MODE" == "many" ]; then
  many
elif [ "$MODE" == "single" ]; then
  single
fi