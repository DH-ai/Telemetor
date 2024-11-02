# Acknowledgement guide

## After Connecting Client Recieve

## Client Recieve : `ACK-CONNECT`

## Client will send

## Server Recieve : `ACK-CONNECT`

## server will send 

## Client Recieve : `ACK-EXCHANGE`

## To start data exchange client will also send `ACK-EXCHANGE`

## Server Recieve : `ACK-EXCHANGE`

## Server send Headers and Types on Complete

## Server Send : HEADER AND TYPES

## Client Recieve : HEADERS AND TYPES

## FORMAT : 'HEADERS{}:TYPES{}'

## If above things clients recieve he will reply

## Client Send : `ACK-COMPLETE`

## Client Ready for getting data

## Data Format : [l fist of data]::ACK(NUMBER)or data integrity 

## ON Loop
## On Recieving data client should reply by ::ACK(NUMBER) 

# Retrying logic for acknoledgments 