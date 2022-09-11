import React, { useCallback } from 'react';
import { CalloutCard, Heading, Link } from '@shopify/polaris';
import { useQuery, useMutation, useQueryClient } from 'react-query';
import { useAppQuery, useAuthenticatedFetch } from '../hooks';

export default function Onboarding() {
  const queryClient = useQueryClient();
  const fetch = useAuthenticatedFetch();
  const {
    isLoading,
    data,
  } = useAppQuery({
    url: "/api/v1/shop"
  });

  const saveMutation = useMutation(
    () => fetch('/api/v1/shop', {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ onboarded: true })
    }).then((response) => response.data),
    {
      onSettled: () => {
        queryClient.invalidateQueries('/api/v1/shop');
      },
    },
  );

  const handleFinished = useCallback(async () => {
    await saveMutation.mutate();
  }, [saveMutation]);

  if (isLoading || data?.shop?.onboarded) return null;

  return (
    <CalloutCard
      title="Getting started"
      primaryAction={{
        content: 'Finished',
        onAction: handleFinished,
      }}
    >
      <Heading>Create a trial plan</Heading>
      <p>
        Trial plans are attached to products that you specify and set the rules for the trial.
        Go to the
        {' '}
        <Link url="/plans/new">trial plan form</Link>
        {' '}
        to create a new plan.
        {' '}
        <b>You must attach products to the plan after you save.</b>
      </p>
      <Heading>Update your theme</Heading>
      <p>
        If your theme uses the Online Store 2.0 system, you can enable
        the app block and place the trial options on the product page.
      </p>
      <p>
        Legacy themes can enable the app embed block to automatically
        add the trial options to the product page.
        {' '}
        <Link external url={`https://${data?.shop?.shopifyDomain}/admin/themes/current/editor?context=apps&template=product&activateAppId=${window.appExtensionUUID}/selling-plans-embed`}>Click here</Link>
        {' '}
        to enable
        the app embed block if you are using a legacy theme.
      </p>
      <Heading>Charging orders</Heading>
      <p>
        Trial orders that are ready to be charged will appear below on this page.
        Click on the order to navigate to the detail page where you will have the option
        to charge the remaining amount on the order.
      </p>
      <Heading>Returns</Heading>
      <p>
        Customers will be able to flag an item for return through the
        {' '}
        <Link external url={`https://${data?.shop?.shopifyDomain}/a/trial/returns/search`}>customer portal</Link>
        on your store. Orders with flagged items will be listed below, and details about which line item is being returned
        can be found in the
        {' '}
        <b>Notes</b>
        {' '}
        section on the order detail page. Once the line item has been restocked, the return
        will be marked as complete. You can also mark as complete in the list below which will mark all line items as returned.
      </p>
    </CalloutCard>
  );
}
