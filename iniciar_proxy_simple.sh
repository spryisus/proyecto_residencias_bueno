#!/bin/bash
cd "$(dirname "$0")/dhl_tracking_proxy"
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "🚀 Iniciando servidor proxy DHL..."
echo "📡 IP local: $LOCAL_IP"
echo "📡 Endpoint: http://$LOCAL_IP:3000/api/track/:trackingNumber"
echo ""
npm start
