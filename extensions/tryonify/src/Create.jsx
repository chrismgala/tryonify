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

export default function Create() {
  const data = useData();
  const { close, done } = useContainer();
  const toast = useToast();
  const { getSessionToken } = useSessionToken();
  const [errors, setErrors] = useState({});

  // Field values
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [sellingPlanName, setSellingPlanName] = useState('');
  const [sellingPlanDescription, setSellingPlanDescription] = useState('');
  const [prepay, setPrepay] = useState(0);
  const [trialDays, setTrialDays] = useState(14);

  const createPlan = async () => {
    try {
      const token = await getSessionToken();
      const resp = await fetch(`https://web-qla9.onrender.com/api/v1/selling_plan_groups`, {
        method: 'POST',
        headers: {
          'authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name,
          description,
          sellingPlan: {
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

  const addProductToPlan = async (id) => {
    try {
      const token = await getSessionToken();
      const resp = await fetch(`https://web-qla9.onrender.com/api/v1/selling_plan_groups/${encodeURIComponent(id)}/products`, {
        method: 'POST',
        headers: {
          'authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          addProducts: [data.productId],
          removeProducts: []
        })
      });

      return resp.json();
    } catch (err) {
      console.err(err);
      toast.show('Product could not be added to trial plan');
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
      const trialPlan = await createPlan();
      await addProductToPlan(trialPlan.id);

      done();
    }
  };

  const cachedActions = useMemo(
    () => (
      <Actions
        onPrimary={onPrimaryAction}
        onClose={close}
        title='Create trial plan'
      />
    ),
    [onPrimaryAction, close]
  );

  return (
    <BlockStack>
      <TextBlock size="extraLarge">Create trial plan</TextBlock>

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
    </BlockStack>
  )
}