# Quick verification script - run on your Windows machine

Write-Host "========================================" -ForegroundColor Green
Write-Host "K3s Cluster Quick Check" -ForegroundColor Green  
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Checking Master Node..." -ForegroundColor Yellow
ssh k8s-master "kubectl get nodes"

Write-Host ""
Write-Host "Checking all pods..." -ForegroundColor Yellow
ssh k8s-master "kubectl get pods -A"

Write-Host ""
Write-Host "Getting K3s token for reference..." -ForegroundColor Yellow
ssh k8s-master "cat /root/k3s-token.txt"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
