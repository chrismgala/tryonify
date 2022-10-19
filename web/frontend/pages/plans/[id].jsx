import React, { useRef, useEffect } from 'react';
import {
  Page,
  PageActions,
  Layout,
  Banner,
  Stack,
} from '@shopify/polaris';
import { useParams } from 'react-router-dom';
import { useMutation, useQueryClient } from 'react-query';
import { useNavigate, useToast } from '@shopify/app-bridge-react';
import { get } from 'lodash';
import { parse } from 'iso8601-duration';
import { useAppQuery, useAuthenticatedFetch } from '../../hooks';
import SellingPlanForm from '../../components/selling-plan-form';
import ProductList from '../../components/product-list';

export default function EditSellingPlan() {
  const fetch = useAuthenticatedFetch();
  const queryClient = useQueryClient();
  const form = useRef(null);
  const params = useParams();
  const toast = useToast();
  const navigate = useNavigate();
  const { isLoading, error, data } = useAppQuery({
    url: `/api/v1/selling_plan_groups/${encodeURIComponent(params.id)}`,
    reactQueryOptions: {
      retry: false,
      onError: (err) => {
        navigate('/plans');
        toast.show('Trial plan not found', { duration: 2000, isError: true });
      }
    }
  });

  let initialValues = {};

  if (data) {
    const sellingPlan = data.sellingPlans.edges[0].node;
    initialValues = {
      name: data.name,
      description: data.description,
      sellingPlan: {
        shopifyId: sellingPlan.id,
        name: sellingPlan.name,
        description: sellingPlan.description,
        prepay: sellingPlan?.billingPolicy?.checkoutCharge?.value?.amount,
        trialDays: parse(sellingPlan?.billingPolicy?.remainingBalanceChargeTimeAfterCheckout).days,
      },
    };
  }

  const saveMutation = useMutation(
    (updatedSellingPlan) => fetch(`/api/v1/selling_plan_groups/${encodeURIComponent(params.id)}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(updatedSellingPlan),
    }).then((response) => response.data),
    {
      onSuccess: (response) => {
        queryClient.setQueryData(['sellingPlanGroup', params.id], response);
      },
    },
  );

  const deleteMutation = useMutation(() => fetch(`/api/v1/selling_plan_groups/${encodeURIComponent(params.id)}`, { method: 'DELETE' }));

  const handleSubmit = async (values, { resetForm }) => {
    await saveMutation.mutate(values);
    resetForm({ values });
  };

  // Show toast on successful submission
  useEffect(() => {
    if (saveMutation.isSuccess) toast.show('Save successful!', { duration: 2000 });
    if (deleteMutation.isSuccess) navigate('/plans');
  }, [saveMutation.isSuccess, deleteMutation.isSuccess, navigate, toast]);

  return (
    <Page
      breadcrumbs={[{ content: 'Back to overview', onAction: () => navigate('/plans') }]}
      title={data?.name}
    >
      <Stack vertical>
        {saveMutation.isError
          && (
            <Banner title="Error" status="critical">
              {get(saveMutation, 'error.response.data.message') ?? saveMutation.error.message}
            </Banner>
          )}

        {deleteMutation.isError
          && (
            <Banner title="Error" status="critical">
              {get(deleteMutation, 'error.response.data.message') ?? deleteMutation.error.message}
            </Banner>
          )}
      </Stack>

      {!isLoading
        && (
          <div style={{ marginTop: '16px' }}>
            <SellingPlanForm initialValues={initialValues} onSubmit={handleSubmit} formRef={form} />
          </div>
        )}

      <div style={{ marginTop: '16px' }}>
        <Layout>
          <Layout.Section>
            <ProductList id={params.id} />
          </Layout.Section>
          <Layout.Section secondary />
          <Layout.Section>
            <PageActions
              primaryAction={{
                content: 'Delete',
                onAction: () => deleteMutation.mutate(),
                destructive: true,
              }}
            />
          </Layout.Section>
        </Layout>
      </div>
    </Page>
  );
}
