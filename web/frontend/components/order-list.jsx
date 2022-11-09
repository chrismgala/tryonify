import React, { useState } from 'react';
import {
  Badge,
  Link,
  IndexTable,
  Stack,
  TextStyle,
} from '@shopify/polaris';
import { useNavigate } from '@shopify/app-bridge-react';
import { useQueryClient } from 'react-query';
import { DateTime } from 'luxon';
import createQueryString from '../lib/utils';
import { useAppQuery, useAuthenticatedFetch } from '../hooks';
import PaymentStatus from './payment-status';

export default function OrderList({ query }) {
  const navigate = useNavigate();
  const fetch = useAuthenticatedFetch();
  const queryClient = useQueryClient();
  const [pagination, setPagination] = useState({
    first: 20,
    query,
  });
  const { isLoading, error, data } = useAppQuery({
    url: `/api/v1/orders?${createQueryString(pagination)}`
  });

  const resourceName = {
    singular: 'order',
    plural: 'orders',
  };

  const rowMarkup = data?.map(
    (order, index) => {
      const {
        id, shopifyId, name, shopifyCreatedAt, financialStatus, dueDate, calculatedDueDate, returns,
      } = order;
      const dt = DateTime.fromISO(calculatedDueDate);
      const tz = dt.zoneName;
      let overdue = false;

      if ((dt <= DateTime.now().setZone(tz)) && financialStatus !== 'PAID') {
        overdue = true;
      }

      const activeReturns = returns.filter(returnItem => returnItem.active).length

      return (
        <IndexTable.Row
          id={id}
          key={id}
          position={index}
        >
          <IndexTable.Cell>
            <Link
              dataPrimaryLink
              url={`/orders/${shopifyId}`}
            >
              <TextStyle variation="strong">{name}</TextStyle>
            </Link>
          </IndexTable.Cell>
          <IndexTable.Cell>
            {new Intl.DateTimeFormat('en-US', { dateStyle: 'long', timeStyle: 'short' }).format(new Date(shopifyCreatedAt))}
          </IndexTable.Cell>
          <IndexTable.Cell>
            {calculatedDueDate && new Intl.DateTimeFormat('en-US', { dateStyle: 'long', timeStyle: 'short' }).format(new Date(calculatedDueDate))}
          </IndexTable.Cell>
          <IndexTable.Cell>
            <Stack spacing="extraTight">
              <PaymentStatus status={financialStatus} />
              {overdue && <PaymentStatus status="OVERDUE" />}
              {activeReturns > 0 && <Badge status='critical'>Returns</Badge>}
            </Stack>
          </IndexTable.Cell>
        </IndexTable.Row>
      );
    },
  );

  return (
    <IndexTable
      resourceName={resourceName}
      loading={isLoading}
      headings={[
        { title: 'Order' },
        { title: 'Created at' },
        { title: 'Due date' },
        { title: 'Status' },
      ]}
      itemCount={data?.length || 0}
      selectable={false}
    >
      {rowMarkup}
    </IndexTable>
  );
}
