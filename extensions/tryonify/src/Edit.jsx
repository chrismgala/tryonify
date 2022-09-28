import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Button,
  BlockStack,
  Card,
  InlineStack,
  TextBlock,
  TextField,
  useContainer,
  useData,
  useSessionToken,
  useToast
} from '@shopify/admin-ui-extensions-react';
import { parse } from 'iso8601-duration';

const validate = (values) => {
  const errors = {};

  if (!values.name) {
    errors.name = 'Required'
  }

  if (!values.sellingPlanName) {
    errors.sellingPlanName = 'Required'
  }

  if (!values.trialDays) {
    errors.trialDays = 'Required'
  }

  return errors;
}

function Actions({ onPrimary, onClose, title }) {
  return (
    <InlineStack inlineAlignment='trailing'>
      <Button title='Cancel' onPress={onClose} />
      <Button title={title} onPress={onPrimary} kind='primary' />
    </InlineStack>
  );
}

export default function Edit() {
  const data = useData();
  const { close, done } = useContainer();
  const toast = useToast();
  const { getSessionToken } = useSessionToken();
  const [errors, setErrors] = useState({});

  // Field values
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [sellingPlanId, setSellingPlanId] = useState('');
  const [sellingPlanName, setSellingPlanName] = useState('');
  const [sellingPlanDescription, setSellingPlanDescription] = useState('');
  const [prepay, setPrepay] = useState(0);
  const [trialDays, setTrialDays] = useState(14);

  const fetchPlan = useCallback(async () => {
    const token = await getSessionToken();
    const resp = await fetch(`https://tryonify.ngrok.io/api/v1/selling_plan_groups/${encodeURIComponent(data.sellingPlanGroupId)}`, {
      headers: {
        'authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      }
    });
    const json = await resp.json();

    setName(json.name);
    setDescription(json.description);

    if (json?.sellingPlans?.edges?.length > 0) {
      setSellingPlanId(json.sellingPlans?.edges[0]?.node?.id);
      setSellingPlanName(json.sellingPlans?.edges[0]?.node?.name)
      setSellingPlanDescription(json.sellingPlans?.edges[0]?.node?.description)
      setPrepay(parseInt(json.sellingPlans?.edges[0]?.node?.billingPolicy?.checkoutCharge?.value?.amount))
      setTrialDays(parse(json.sellingPlans?.edges[0]?.node?.billingPolicy?.remainingBalanceChargeTimeAfterCheckout).days)
    }
  }, []);

  const updatePlan = async () => {
    try {
      const token = await getSessionToken();
      const resp = await fetch(`https://tryonify.ngrok.io/api/v1/selling_plan_groups/${encodeURIComponent(data.sellingPlanGroupId)}`, {
        method: 'PUT',
        headers: {
          'authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name,
          description,
          sellingPlan: {
            shopifyId: sellingPlanId,
            name: sellingPlanName,
            description: sellingPlanDescription,
            prepay,
            trialDays,
          },
        })
      });

      return resp.json();
    } catch (err) {
      console.err(err);
      toast.show('Trial plan could not be created');
    }
  };

  const onPrimaryAction = async () => {
    const validation = validate({
      name,
      sellingPlanName,
      trialDays,
    });

    if (Object.keys(validation).length > 0) {
      setErrors(validation);
    } else {
      await updatePlan();

      done();
    }
  };

  const cachedActions = useMemo(
    () => (
      <Actions
        onPrimary={onPrimaryAction}
        onClose={close}
        title='Update trial plan'
      />
    ),
    [onPrimaryAction, close]
  );

  useEffect(() => {
    fetchPlan();
  }, []);

  return (
    <>
      <BlockStack spacing="none">
        <TextBlock size="extraLarge">Update trial plan</TextBlock>
      </BlockStack>

      <Card title="Admin Details" sectioned>
        <BlockStack>
          <TextField
            label="Name"
            name="name"
            onChange={setName}
            value={name}
            error={errors.name}
          />
          <TextField
            label="Description"
            name="description"
            multiline={4}
            onChange={setDescription}
            value={description}
          />
        </BlockStack>
      </Card>

      <Card title="Customer Details" sectioned>
        <BlockStack>
          <TextField
            label="Name"
            name="sellingPlan[name]"
            onChange={setSellingPlanName}
            value={sellingPlanName}
            error={errors.sellingPlanName}
          />
          <TextField
            label="Description"
            name="sellingPlan[description]"
            multiline={4}
            onChange={setSellingPlanDescription}
            value={sellingPlanDescription}
          />
        </BlockStack>
      </Card>

      <Card title="Payment Terms" sectioned>
        <InlineStack inlineAlignment='fill'>
          <TextField
            label="Pre-paid Amount"
            name="sellingPlan[prepay]"
            type="number"
            onChange={setPrepay}
            value={prepay}
          />
          <TextField
            label="Trial Length (Days)"
            name="sellingPlan[trialDays]"
            type="number"
            onChange={setTrialDays}
            value={trialDays}
            error={errors.trialDays}
          />
        </InlineStack>
      </Card>

      {cachedActions}
    </>
  )
}