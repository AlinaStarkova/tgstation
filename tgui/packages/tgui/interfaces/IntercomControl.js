import { map, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { toFixed } from 'common/math';
import { pureComponentHooks } from 'common/react';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Dimmer, Flex, Icon, Table, Tabs, LabeledList, NumberInput, Section } from '../components';
import { RADIO_CHANNELS } from '../constants';
import { Window } from '../layouts';

export const IntercomControl = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    frequency,
  } = data;
  const tunedChannel = RADIO_CHANNELS
    .find(channel => channel.freq === frequency);
  const channels = map((value, key) => ({
    name: key,
    status: !!value,
  }))(data.channels);
  return (
    <Window
      title="Intercom Controller"
      width={550}
      height={500}
      resizable>
      {data.authenticated === 1 && (
        <IntercomLoggedIn />
      )}
      {data.authenticated === 0 && (
        <IntercomLoggedOut />
      )}
    </Window>
  );
};

const IntercomLoggedOut = (props, context) => {
  const { act, data } = useBackend(context);
  const { emagged } = data;
  const text = emagged === 1 ? 'Open' : 'Log In';
  return (
    <Window.Content>
      <Button
        fluid
        color={emagged === 1 ? '' : 'good'}
        content={text}
        onClick={() => act('log-in')} />
    </Window.Content>
  );
};

const IntercomLoggedIn = (props, context) => {
  const { act, data } = useBackend(context);
  const { restoring } = data;
  const [
    tabIndex,
    setTabIndex,
  ] = useLocalState(context, 'tab-index', 1);
  return (
    <>
      <Tabs>
        <Tabs.Tab
          selected={tabIndex === 1}
          onClick={() => {
            setTabIndex(1);
            act('check-intercoms');
          }}>
          Intercom Control Panel
        </Tabs.Tab>
        <Tabs.Tab
          selected={tabIndex === 2}
          onClick={() => {
            setTabIndex(2);
            act('check-logs');
          }}>
          Log View Panel
        </Tabs.Tab>
      </Tabs>
      {restoring === 1 && (
        <Dimmer fontSize="32px">
          <Icon name="cog" spin />
          {' Resetting...'}
        </Dimmer>
      )}
      {tabIndex === 1 && (
        <>
          <ControlPanel />
          <Box fillPositionedParent top="53px">
            <Window.Content scrollable>
              <IntercomControlScene />
            </Window.Content>
          </Box>
        </>
      )}
      {tabIndex === 2 && (
        <Box fillPositionedParent top="20px">
          <Window.Content scrollable>
            <LogPanel />
          </Window.Content>
        </Box>
      )}
    </>
  );
};

const ControlPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    emagged,
    logging,
  } = data;
  const [
    sortByField,
    setSortByField,
  ] = useLocalState(context, 'sortByField', null);
  return (
    <Flex>
      <Flex.Item>
        <Box inline mr={2} color="label">
          Sort by:
        </Box>
        <Button.Checkbox
          checked={sortByField === 'name'}
          content="Name"
          onClick={() => setSortByField(sortByField !== 'name' && 'name')} />
      </Flex.Item>
      <Flex.Item grow={1} />
      <Flex.Item>
        {emagged === 1 && (
          <>
            <Button
              color={logging === 1 ? 'bad' : 'good'}
              content={logging === 1 ? 'Stop Logging' : 'Restore Logging'}
              onClick={() => act('toggle-logs')}
            />
            <Button
              content="Reset Console"
              onClick={() => act('restore-console')}
            />
          </>
        )}
        <Button
          color="bad"
          content="Log Out"
          onClick={() => act('log-out')}
        />
      </Flex.Item>
    </Flex>
  );
};

const IntercomControlScene = (props, context) => {
  const { data, act } = useBackend(context);
  const {
    freqlock,
    frequency,
    minFrequency,
    maxFrequency,
    listening,
    broadcasting,
    command,
    useCommand,
    subspace,
    subspaceSwitchable,
  } = data;
  const channels = map((value, key) => ({
    name: key,
    status: !!value,
  }))(data.channels);
  const [
    sortByField,
  ] = useLocalState(context, 'sortByField', null);

  const intercoms = flow([
    map((intercom, i) => ({
      ...intercom,
      // Generate a unique id
      id: intercom.name + i,
    })),
    sortByField === 'name' && sortBy(intercom => intercom.name),
  ])(data.intercoms);
  const tunedChannel = RADIO_CHANNELS
  .find(channel => channel.freq === frequency);
  return (
    <Table>
      <Table.Row header>
        <Table.Cell>
          Name
        </Table.Cell>
      </Table.Row>
      {intercoms.map((intercom, i) => (
        <tr
          key={intercom.id}
          className="Table__row  candystripe">
          <td>
            {intercom.name}
          </td>
          <td>
          {freqlock && (
                <Box inline color="light-gray">
                  {toFixed(intercom.frequency / 10, 1) + ' kHz'}
                </Box>
              ) || (
                <NumberInput
                  target="frequency"
                  intercom={intercom}
                  animate
                  unit="kHz"
                  step={0.2}
                  stepPixelSize={10}
                  minValue={minFrequency / 10}
                  maxValue={maxFrequency / 10}
                  value={intercom.frequency / 10}
                  format={value => toFixed(value, 1)}
                  onDrag={(e, value) => act('frequency', {
                    adjust: (value - intercom.frequency / 10), ref: intercom.ref,
                  })} />)}
              {tunedChannel && (
                <Box inline color={tunedChannel.color} ml={2}>
                  [{tunedChannel.name}]
                </Box>
              )}
          </td>
          <td className="Table__cell text-center text-nowrap">
            <ListeningStatusColorButton
              target="listening"
              status={intercom.listening}
              selected={listening}
              intercom={intercom}
              act={act}
              />
          </td>
          <td className="Table__cell text-center text-nowrap">
            <BroadcastingStatusColorButton
              target="broadcasting"
              status={intercom.broadcasting}
              selected={broadcasting}
              intercom={intercom}
              act={act}
            />
          </td>
        </tr>
      ))}
    </Table>
  );
};

const LogPanel = (props, context) => {
  const { data } = useBackend(context);

  const logs = flow([
    map((line, i) => ({
      ...line,
      // Generate a unique id
      id: line.entry + i,
    })),
    logs => logs.reverse(),
  ])(data.logs);
  return (
    <Box m={-0.5}>
      {logs.map(line => (
        <Box
          p={0.5}
          key={line.id}
          className="candystripe"
          bold>
          {line.entry}
        </Box>
      ))}
    </Box>
  );
};

const ListeningStatusColorButton = props => {
  const { target, status, intercom, act } = props;
  const power = Boolean(status & 1);
  const listening = Boolean(status & 1);
  return (
    <Button
      icon={listening ? 'volume-up' : 'volume-mute'}
      color={power ? 'good' : 'bad'}
      onClick={() => act('toggle-minor', {
        type: target,
        value: statusChange(status),
        ref: intercom.ref,
      })}
    />
  );
};

const BroadcastingStatusColorButton = props => {
  const { target, status, intercom, act } = props;
  const power = Boolean(status & 1);
  const broadcasting = Boolean(status & 1);
  return (
    <Button
      icon={broadcasting ? 'microphone' : 'microphone-slash'}
      color={power ? 'good' : 'bad'}
      onClick={() => act('toggle-minor', {
        type: target,
        value: statusChange(status),
        ref: intercom.ref,
      })}
    />
  );
};

const statusChange = status => {
  // mode flip power flip both flip
  // 0, 2, 3
  return status ?  0 : 1;
};

ListeningStatusColorButton.defaultHooks = pureComponentHooks;
BroadcastingStatusColorButton.defaultHooks = pureComponentHooks;

