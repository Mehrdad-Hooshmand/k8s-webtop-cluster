# Check Installation Progress
# Run this on your Windows machine to check background installations

Write-Host "========================================" -ForegroundColor Green
Write-Host "Checking Installation Progress" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "=== Cluster Nodes ===" -ForegroundColor Yellow
ssh -p 2280 root@94.182.92.207 "kubectl get nodes"
Write-Host ""

Write-Host "=== All Namespaces ===" -ForegroundColor Yellow
ssh -p 2280 root@94.182.92.207 "kubectl get ns"
Write-Host ""

Write-Host "=== Longhorn Status ===" -ForegroundColor Yellow
ssh -p 2280 root@94.182.92.207 "kubectl get pods -n longhorn-system 2>/dev/null || echo 'Longhorn not yet created'"
Write-Host ""

Write-Host "=== Longhorn Install Log (last 20 lines) ===" -ForegroundColor Yellow
ssh -p 2280 root@94.182.92.207 "tail -20 /root/longhorn-install.log 2>/dev/null || echo 'Log not available yet'"
Write-Host ""

Write-Host "=== Storage Classes ===" -ForegroundColor Yellow
ssh -p 2280 root@94.182.92.207 "kubectl get sc"
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "To see full Longhorn log:" -ForegroundColor Cyan
Write-Host "  ssh -p 2280 root@94.182.92.207 'tail -f /root/longhorn-install.log'" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
