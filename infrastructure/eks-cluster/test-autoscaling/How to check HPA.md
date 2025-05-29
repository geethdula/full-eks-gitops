> Apply hpa-sample manifest.yaml to k8s cluster
kubectl apply -f test-hpa/hpa-sample.yaml

> Then run load test against it, then inside container 
# while true; do wget -q -O- http://php-apache; done
> Run multiple loeads
kubectl run -i --tty load-generator --image=busybox /bin/sh
kubectl run -i --tty load-generator-2 --image=busybox /bin/sh


> Ube below command to check scaling
kubectl get hpa -w
kubectl get pods -w