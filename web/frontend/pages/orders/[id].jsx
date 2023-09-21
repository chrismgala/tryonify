import React from 'react';
import {
  Badge,
  Page,
  Layout,
  Card,
  IndexTable,
  SkeletonBodyText,
  Stack,
  Text,
  Thumbnail
} from '@shopify/polaris';
import { ImageMajor } from '@shopify/polaris-icons';
import { useParams } from 'react-router-dom';
import { useNavigate, useToast } from '@shopify/app-bridge-react';
import { DateTime } from 'luxon';
import { useAppQuery } from '../../hooks';

export default function EditSellingPlan() {
  const params = useParams();
  const toast = useToast();
  const navigate = useNavigate();
  const { isLoading, error, data } = useAppQuery({
    url: `/api/v1/orders/${encodeURIComponent(params.id)}`,
    reactQueryOptions: {
      retry: false,
      onError: (err) => {
        navigate('/');
        toast.show('Order not found', { duration: 2000, isError: true });
      }
    }
  });

  const resourceName = {
    singular: 'product',
    plural: 'products'
  }

  const rowMarkup = data?.lineItems.map(lineItem => {
    const { id, title, variantTitle, imageUrl, quantity } = lineItem;
    let status = { level: 'warning', label: 'Pending' };

    if (data?.financialStatus === 'PAID') {
      status = { level: 'success', label: 'Paid' };
    }

    const returnItem = data?.returns?.find(returnItem => returnItem.shopifyId === id);

    if (returnItem) {
      if (returnItem.active) {
        status = { level: 'critical', label: 'Returning' };
      } else {
        status = { level: 'info', label: 'Returned' };
      }
    }

    return (
      <IndexTable.Row
        id={id}
        key={id}
      >
        <IndexTable.Cell>
          <Stack>
            <Thumbnail source={imageUrl || ImageMajor} alt={title} />
            <Text variant="bodyMd" fontWeight="bold" as="span">{title}</Text>
            <span>{variantTitle}</span>
          </Stack>
        </IndexTable.Cell>
        <IndexTable.Cell>
          {quantity}
        </IndexTable.Cell>
        <IndexTable.Cell>
          <Badge status={status.level}>{status.label}</Badge>
        </IndexTable.Cell>
      </IndexTable.Row>
    )
  })

  return (
    <Page
      breadcrumbs={[{ content: 'Back to overview', onAction: () => navigate('/') }]}
      title={data?.name}
      primaryAction={{
        content: 'View Order',
        onAction: () => navigate({
          name: 'Order',
          resource: { id: data?.shopifyId.split('/').pop() }
        })
      }}
    >
      <Layout>
        <Layout.Section>
          <Card title='Line Items'>
            <IndexTable
              itemCount={data?.lineItems.length || 0}
              resourceName={resourceName}
              headings={[
                { title: 'Product' },
                { title: 'Quantity' },
                { title: 'Status' },
              ]}
              selectable={false}
              loading={isLoading}
            >
              {rowMarkup}
            </IndexTable>
          </Card>
        </Layout.Section>

        <Layout.Section oneThird>
          <Card title='Payment Details'>
            <Card.Section title='Due Date'>
              {isLoading ? (
                <SkeletonBodyText />
              ) : (
                <span>{data?.cancelledAt ? 'Cancelled' : DateTime.fromISO(data?.calculatedDueDate).toLocaleString()}</span>
              )}
            </Card.Section>
          </Card>
        </Layout.Section>
      </Layout>
    </Page>
  );
}
