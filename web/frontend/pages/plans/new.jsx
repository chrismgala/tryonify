import React, { useRef, useEffect } from 'react';
import {
  Page,
  Layout,
  Banner,
  Stack,
} from '@shopify/polaris';
import { useMutation, useQueryClient } from 'react-query';
import { useNavigate } from '@shopify/app-bridge-react';
import { get } from 'lodash';
import { useAuthenticatedFetch } from '../../hooks';
import SellingPlanForm from '../../components/selling-plan-form';

const initialValues = {
  name: '',
  description: '',
  sellingPlan: {
    name: '',
    description: '',
    prepay: 0,
    trialDays: 14,
  },
};

export default function NewSellingPlan() {
  const queryClient = useQueryClient();
  const fetch = useAuthenticatedFetch();
  const form = useRef(null);
  const navigate = useNavigate();
  const saveMutation = useMutation((newSellingPlan) => fetch('/api/v1/selling_plan_groups', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(newSellingPlan)
  }).then(async response => await response.json()), {
    onSuccess: (data) => {
      queryClient.setQueryData(['sellingPlanGroup', data.id], data);
    },
  });

  const handleSubmit = async (values, { resetForm }) => {
    await saveMutation.mutate(values);
    resetForm({ values });
  };

  // Navigate to list on successful form submission
  useEffect(() => {
    if (saveMutation.isSuccess) navigate(`/plans/${encodeURIComponent(saveMutation.data?.id)}`);
  }, [saveMutation, navigate]);

  return (
    <Page
      breadcrumbs={[{ content: 'Back to list', onAction: () => navigate('/plans') }]}
      title="Create Selling Plan"
    >
      <Layout>
        <Layout.Section>
          <Stack vertical>
            {saveMutation.isError
              && (
                <Banner title="Error" status="critical">
                  {get(saveMutation, 'error.response.data.message') ?? saveMutation.error.message}
                </Banner>
              )}
          </Stack>
        </Layout.Section>
      </Layout>
      <SellingPlanForm
        initialValues={initialValues}
        onSubmit={handleSubmit}
        formRef={form}
      />
    </Page>
  );
}
