# Mesque

A Resque compatible work library using RabbitMQ as backend for relability and performance.

### RabbitMQ

RabbitMQ is a efficent, purpose built message queue server. Where as Resque by default has a quite insecure and slow way of queueing and distributing work, RabbitMQ pushes out work messages to workers, in order. 

All messages are persisted to disk by default, so in any kind of event messages are always safe. RabbitMQ also has a cluster mechanism so that all messages can automatically be mirrored between two or more nodes, so if one nodes goes unavailable workers can reconnect to a second node and contiune subscribe to work with minimal interuption. 

In Resque and Sidekiq (not Pro) the worker pulls message from Redis and only holds it in memory, so if the worker is killed for any reason and the message isn't processed you have lost the message for ever. In RabbitMQ on the otherhand messages has to be "acknowledged" before it's deleted from the queue. If a Mesque worker is killed the message will simply be requeued and another worker will pick it up. 

### End to end encryption

To protected your messages from eavesdropping all messages are by default encrypted with AES-256-CBC
