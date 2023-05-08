import React from 'react';
import { Badge } from '@shopify/polaris';

export default function PaymentStatus({ status }) {
  let badgeStatus = 'default';

  switch (status) {
    case 'PENDING':
      badgeStatus = 'warning';
      break;
    case 'DUE_TODAY':
      badgeStatus = 'warning';
      break;
    case 'OVERDUE':
      badgeStatus = 'critical';
      break;
    case 'PARTIALLY_PAID':
      badgeStatus = 'warning';
      break;
    case 'PAID':
      badgeStatus = 'success';
      break;
    default:
      break;
  }

  return (
    <Badge status={badgeStatus}>
      <span style={{ textTransform: 'capitalize' }}>{status.toLowerCase().replace('_', ' ')}</span>
    </Badge>
  );
}
