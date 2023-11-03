import React, { useCallback, useState } from 'react';
import {
  Badge,
  Button,
  DatePicker,
  Page,
  Popover,
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
import { useMutation, useQueryClient } from 'react-query';
import { useAppQuery, useAuthenticatedFetch } from '../../hooks';
import SaveBar from '../../components/save-bar';

export default function EditSellingPlan() {
  const params = useParams();
  const toast = useToast();
  const navigate = useNavigate();
  const fetch = useAuthenticatedFetch();
  const queryClient = useQueryClient();
  const [dueDateActive, setDueDateActive] = useState(false);
  const [selectedDueDate, setSelectedDueDate] = useState(null);
  const [selectedYearMonth, setSelectedYearMonth] = useState({year: 1, month: 0});
  const { isLoading, error, data } = useAppQuery({
    url: `/api/v1/orders/${encodeURIComponent(params.id)}`,
    reactQueryOptions: {
      retry: false,
      onSuccess: (data) => {
        setSelectedDueDate(DateTime.fromISO(data?.dueDate).toJSDate());
        setSelectedYearMonth({year: DateTime.fromISO(data?.dueDate).year, month: DateTime.fromISO(data?.dueDate).month - 1});
      },
      onError: (err) => {
        navigate('/');
        toast.show('Order not found', { duration: 2000, isError: true });
      }
    }
  });

  const saveMutation = useMutation(
    (dueDate) => fetch(`/api/v1/orders/${encodeURIComponent(params.id)}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ dueDate })
    }).then(async (response) => await response.json()),
    {
      onSuccess: (data) => {
        queryClient.invalidateQueries(`/api/v1/orders/${encodeURIComponent(params.id)}`);
        toast.show('Order updated', { duration: 2000 });
      },
      onError: (err) => {
        toast.show('Order not updated', { duration: 2000, isError: true });
      }
    }
  )

  const toggleDueDateActive = useCallback(
    () => setDueDateActive((dueDateActive) => !dueDateActive),
    [],
  );

  const handleMonthChange = useCallback(
    (month, year) => setSelectedYearMonth({month, year}), []
  )

  const handleSave = useCallback(
    () => saveMutation.mutate(selectedDueDate), [selectedDueDate]
  )

  const handleReset = useCallback(
    () => {
      setSelectedDueDate(DateTime.fromISO(data?.dueDate).toJSDate());
    }, [data]
  )

  const resourceName = {
    singular: 'product',
    plural: 'products'
  }

  const rowMarkup = data?.lineItems.map(lineItem => {
    const { id, shopifyId, title, variantTitle, imageUrl, quantity } = lineItem;
    let status = { level: 'warning', label: 'Pending' };

    if (data?.financialStatus === 'PAID') {
      status = { level: 'success', label: 'Paid' };
    }

    const returnItem = data?.returns?.find(returnItem => returnItem.shopifyId === shopifyId);

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

  const activator = isLoading ? null : (
    <Button onClick={toggleDueDateActive}>
      <span>{data?.cancelledAt ? 'Cancelled' : selectedDueDate.toLocaleDateString()}</span>
    </Button>
  )

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
      <SaveBar
        dirty={isLoading ? false : (DateTime.fromISO(data?.dueDate).toMillis() !== DateTime.fromJSDate(selectedDueDate).toMillis())}
        submitForm={handleSave}
        resetForm={handleReset}
      />
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
                (data?.cancelledAt || data?.fullyPaid) ? (
                  <span>{data?.cancelledAt ? 'Cancelled' : selectedDueDate.toLocaleDateString()}</span>
                ) : (
                  <Popover
                  active={dueDateActive}
                  activator={activator}
                  onClose={toggleDueDateActive}
                  sectioned
                >
                  <DatePicker
                    month={selectedYearMonth.month}
                    year={selectedYearMonth.year}
                    onChange={({ start }) => setSelectedDueDate(start)}
                    onMonthChange={handleMonthChange}
                    selected={selectedDueDate}
                    allowRange={false}
                  />
                </Popover>
                )
              )}
            </Card.Section>
          </Card>
        </Layout.Section>
      </Layout>
    </Page>
  );
}
