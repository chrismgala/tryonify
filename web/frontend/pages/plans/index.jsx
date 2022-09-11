import React, { useState } from 'react';
import { useNavigate } from '@shopify/app-bridge-react';
import {
  Page,
  Layout,
  Card,
} from '@shopify/polaris';
import { useAppQuery } from '../../hooks';
import createQueryString from '../../lib/utils';
import SellingPlanList from '../../components/selling-plan-list';

export default function ListSellingPlans() {
  const [pagination, setPagination] = useState({
    first: 20,
  });
  const { isLoading, error, data } = useAppQuery({
    url: `/api/v1/selling_plan_groups?${createQueryString(pagination)}`
  });
  const navigate = useNavigate();

  const primaryAction = {
    content: 'New Plan',
    onAction: () => navigate('/plans/new'),
  }

  return (
    <Page
      breadcrumbs={[{ content: 'Back to overview', onAction: () => navigate('/') }]}
      title="Trial Plans"
      primaryAction={primaryAction}
    >
      <Layout>
        <Layout.Section>
          <Card>
            {isLoading ? (
              <div />
            ) : (
              <SellingPlanList items={data?.edges || []} onAction={() => navigate('/plans/new')} />
            )}
          </Card>
        </Layout.Section>
      </Layout>
    </Page>
  );
}
