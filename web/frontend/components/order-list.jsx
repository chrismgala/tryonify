import React, { useState } from 'react';
import {
  Card,
  Link,
  IndexTable,
  Stack,
  TextStyle,
} from '@shopify/polaris';
import { useNavigate } from '@shopify/app-bridge-react';
import { useQueryClient } from 'react-query';
import createQueryString from '../lib/utils';
import { useAppQuery, useAuthenticatedFetch } from '../hooks';
import PaymentStatus from './payment-status';

export default function OrderList({ title, query }) {
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
        id, shopifyId, name, shopifyCreatedAt, financialStatus, dueDate,
      } = order;
      const overdue = new Date(dueDate).getTime() < new Date().getTime();

      return (
        <IndexTable.Row
          id={id}
          key={id}
          position={index}
        >
          <IndexTable.Cell>
            <Link
              dataPrimaryLink
              onClick={() => {
                navigate({
                  name: 'Order',
                  resource: { id: shopifyId },
                });
              }}
            >
              <TextStyle variation="strong">{name}</TextStyle>
            </Link>
          </IndexTable.Cell>
          <IndexTable.Cell>
            {new Intl.DateTimeFormat('en-US', { dateStyle: 'long', timeStyle: 'short' }).format(new Date(shopifyCreatedAt))}
          </IndexTable.Cell>
          <IndexTable.Cell>
            {dueDate && new Intl.DateTimeFormat('en-US', { dateStyle: 'long', timeStyle: 'short' }).format(new Date(dueDate))}
          </IndexTable.Cell>
          <IndexTable.Cell>
            <Stack spacing="extraTight">
              <PaymentStatus status={financialStatus} />
              {overdue && <PaymentStatus status="OVERDUE" />}
            </Stack>
          </IndexTable.Cell>
        </IndexTable.Row>
      );
    },
  );

  return (
    <Card title={title}>
      <IndexTable
        resourceName={resourceName}
        loading={isLoading}
        headings={[
          { title: 'Order' },
          { title: 'Created at' },
          { title: 'Due date' },
          { title: 'Payment status' },
        ]}
        itemCount={data?.length || 0}
        selectable={false}
      >
        {rowMarkup}
      </IndexTable>
    </Card>
  );
}
