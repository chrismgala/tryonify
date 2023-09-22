import React, { useState, useCallback } from 'react';
import {
  Badge,
  Card,
  Link,
  IndexTable,
  Pagination,
  Stack,
  TextStyle,
} from '@shopify/polaris';
import { DateTime } from 'luxon';
import createQueryString from '../lib/utils';
import { useAppQuery } from '../hooks';
import PaymentStatus from './payment-status';

const getPaymentDueStatus = order => {
  const { totalOutstanding, dueDate, fullyPaid } = order;

  if (totalOutstanding <= 0 || fullyPaid) return null;

  const dt = DateTime.fromISO(dueDate);

  if (dt.toISODate() === DateTime.utc().toISODate()) {
    return 'DUE_TODAY';
  }

  if (dt < DateTime.utc()) {
    return 'OVERDUE';
  }

  return null;
}

export default function OrderList({ status, query }) {
  const [pagination, setPagination] = useState({
    page: 1,
  });
  const { isLoading, error, data } = useAppQuery({
    url: `/api/v1/orders?${createQueryString({
      ...pagination,
      query,
      status,
    })}`,
    debounceWait: 300
  });

  const handlePage = useCallback((page) => {
    setPagination(prevValue => ({
      ...prevValue,
      page,
    }))
  }, []);

  const resourceName = {
    singular: 'order',
    plural: 'orders',
  };

  const rowMarkup = data?.results?.map(
    (order, index) => {
      const {
        id,
        name,
        shopifyCreatedAt,
        financialStatus,
        dueDate,
        cancelledAt,
        returns,
      } = order;
      const paymentDueStatus = getPaymentDueStatus(order);
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
              url={`/orders/${id}`}
            >
              <TextStyle variation="strong">{name}</TextStyle>
            </Link>
          </IndexTable.Cell>
          <IndexTable.Cell>
            {new Intl.DateTimeFormat('en-US', { dateStyle: 'long', timeStyle: 'short' }).format(new Date(shopifyCreatedAt))}
          </IndexTable.Cell>
          <IndexTable.Cell>
            {(dueDate && !cancelledAt) ? (
              new Intl.DateTimeFormat('en-US', { dateStyle: 'long', timeStyle: 'short' }).format(new Date(dueDate))
            ) : (
              <span>--</span>
            )}
          </IndexTable.Cell>
          <IndexTable.Cell>
            <Stack spacing="extraTight">
              {cancelledAt && <Badge>Cancelled</Badge>}
              <PaymentStatus status={financialStatus} />
              {paymentDueStatus && <PaymentStatus status={paymentDueStatus} />}
              {activeReturns > 0 && <Badge status='critical'>Returns</Badge>}
            </Stack>
          </IndexTable.Cell>
        </IndexTable.Row>
      );
    },
  );

  const { totalPages, currentPage, nextPage, prevPage } = data?.pagination ?? {}

  return (
    <>
      <IndexTable
        resourceName={resourceName}
        loading={isLoading}
        headings={[
          { title: 'Order' },
          { title: 'Created at' },
          { title: 'Due date' },
          { title: 'Status' },
        ]}
        itemCount={data?.results?.length || 0}
        selectable={false}
      >
        {rowMarkup}
      </IndexTable>
      <Card.Section>
        <Stack distribution="center" wrap={false}>
          {totalPages > 0 &&
            <Pagination
              label={`Page ${currentPage} of ${totalPages}`}
              onNext={() => handlePage(nextPage)}
              hasNext={nextPage}
              onPrevious={() => handlePage(prevPage)}
              hasPrevious={prevPage}
            />
          }
        </Stack>
      </Card.Section>
    </>
  );
}
