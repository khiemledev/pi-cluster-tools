#!/bin/bash

kubectl delete pod <PODNAME> --grace-period=0 --force --namespace <NAMESPACE>