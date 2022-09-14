import React, { useState, useCallback } from 'react';
import {
  Button,
  Card,
  Link,
  IndexTable,
  Stack,
  TextStyle,
} from '@shopify/polaris';
import { useNavigate } from '@shopify/app-bridge-react';
import { useMutation, useQueryClient } from 'react-query';
import { useAppQuery, useAuthenticatedFetch } from '../hooks';
import createQueryString from '../lib/utils';
import PaymentStatus from './payment-status';

export default function ReturnList({ title }) {
  const navigate = useNavigate();
  const fetch = useAuthenticatedFetch();
  const queryClient = useQueryClient();
  const [pagination, setPagination] = useState({
    first: 20,
  });
  const { isLoading, error, data } = useAppQuery({
    url: `/api/v1/returns?${createQueryString(pagination)}`,
    reactQueryOptions: {
      keepPreviousData: true,
    }
  });

  const saveMutation = useMutation(
    (orderId) => fetch(`/api/v1/returns/${orderId}`, {
      method: 'PUT'
    })
      .then((response) => response.data),
    {
      onSettled: () => {
        queryClient.invalidateQueries(`/api/v1/returns?${createQueryString(pagination)}`);
      },
    },
  );

  const handleMarkAsReturned = useCallback((id) => {
    saveMutation.mutate(id);
  }, [saveMutation]);

  const resourceName = {
    singular: 'return',
    plural: 'returns',
  };

  const rowMarkup = data?.map(
    (order, index) => {
      const {
        id, shopifyId, name, createdAt, status, dueDate,
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
            {new Intl.DateTimeFormat('en-US', { dateStyle: 'long', timeStyle: 'short' }).format(new Date(createdAt))}
          </IndexTable.Cell>
          <IndexTable.Cell>
            {dueDate && new Intl.DateTimeFormat('en-US', { dateStyle: 'long', timeStyle: 'short' }).format(new Date(dueDate))}
          </IndexTable.Cell>
          <IndexTable.Cell>
            <Stack spacing="extraTight">
              <PaymentStatus status={status} />
              {overdue && <PaymentStatus status="OVERDUE" />}
            </Stack>
          </IndexTable.Cell>
          <IndexTable.Cell>
            <Button onClick={() => handleMarkAsReturned(id)}>
              Mark as returned
            </Button>
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
          { title: '' },
        ]}
        itemCount={data?.length || 0}
        selectable={false}
      >
        {rowMarkup}
      </IndexTable>
    </Card>
  );
}
