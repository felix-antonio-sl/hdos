# FHIR R4 Resource Reference Relationships

> Compiled from the official HL7 FHIR R4 specification (https://hl7.org/fhir/R4/)
> Purpose: ERD diagram construction
> Scope: 37 resources with outgoing references, incoming references, key attributes, and cardinalities

---

## Table of Contents

1. [Patient](#1-patient)
2. [Encounter](#2-encounter)
3. [EpisodeOfCare](#3-episodeofcare)
4. [Location](#4-location)
5. [Organization](#5-organization)
6. [Practitioner](#6-practitioner)
7. [PractitionerRole](#7-practitionerrole)
8. [CareTeam](#8-careteam)
9. [CarePlan](#9-careplan)
10. [Condition](#10-condition)
11. [Procedure](#11-procedure)
12. [Observation](#12-observation)
13. [MedicationRequest](#13-medicationrequest)
14. [MedicationAdministration](#14-medicationadministration)
15. [MedicationDispense](#15-medicationdispense)
16. [ServiceRequest](#16-servicerequest)
17. [Task](#17-task)
18. [Appointment](#18-appointment)
19. [Schedule](#19-schedule)
20. [Slot](#20-slot)
21. [Device](#21-device)
22. [DeviceRequest](#22-devicerequest)
23. [SupplyRequest](#23-supplyrequest)
24. [SupplyDelivery](#24-supplydelivery)
25. [Communication](#25-communication)
26. [Flag](#26-flag)
27. [Consent](#27-consent)
28. [Coverage](#28-coverage)
29. [Claim](#29-claim)
30. [QuestionnaireResponse](#30-questionnaireresponse)
31. [DocumentReference](#31-documentreference)
32. [MessageHeader](#32-messageheader)
33. [Provenance](#33-provenance)
34. [AllergyIntolerance](#34-allergyintolerance)
35. [Goal](#35-goal)
36. [NutritionOrder](#36-nutritionorder)
37. [Composition](#37-composition)
38. [Cross-Reference Matrix](#38-cross-reference-matrix)

---

## 1. Patient

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| active | boolean | 0..1 |
| name | HumanName | 0..* |
| telecom | ContactPoint | 0..* |
| gender | code | 0..1 |
| birthDate | date | 0..1 |
| deceased[x] | boolean / dateTime | 0..1 |
| address | Address | 0..* |
| maritalStatus | CodeableConcept | 0..1 |
| multipleBirth[x] | boolean / integer | 0..1 |
| photo | Attachment | 0..* |

**Outgoing References (Patient references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| generalPractitioner | Organization, Practitioner, PractitionerRole | 0..* |
| managingOrganization | Organization | 0..1 |
| contact.organization | Organization | 0..1 |
| link.other | Patient, RelatedPerson | 1..1 |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Encounter | subject |
| EpisodeOfCare | patient |
| CareTeam | subject, participant.member |
| CarePlan | subject, author, contributor, activity.detail.performer |
| Condition | subject, recorder, asserter |
| Procedure | subject, recorder, asserter, performer.actor |
| Observation | subject, performer |
| MedicationRequest | subject, requester, performer, reportedReference |
| MedicationAdministration | subject, performer.actor |
| MedicationDispense | subject, performer.actor, receiver |
| ServiceRequest | subject, requester, performer |
| Task | for, requester, owner, restriction.recipient |
| Appointment | participant.actor |
| Schedule | actor |
| Device | patient |
| DeviceRequest | subject |
| SupplyDelivery | patient |
| Communication | subject, recipient, sender |
| Flag | subject, author |
| Consent | patient, performer, provision.actor.reference, verification.verifiedWith |
| Coverage | policyHolder, subscriber, beneficiary, payor |
| Claim | patient |
| QuestionnaireResponse | subject, author, source |
| DocumentReference | subject |
| Provenance | agent.who, agent.onBehalfOf |
| AllergyIntolerance | patient, recorder, asserter |
| Goal | subject, expressedBy |
| NutritionOrder | patient |
| Composition | subject, author, attester.party, section.author |
| CarePlan | subject |
| SupplyRequest | deliverTo |

---

## 2. Encounter

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code (EncounterStatus) | 1..1 |
| class | Coding | 1..1 |
| type | CodeableConcept | 0..* |
| serviceType | CodeableConcept | 0..1 |
| priority | CodeableConcept | 0..1 |
| period | Period | 0..1 |
| length | Duration | 0..1 |
| reasonCode | CodeableConcept | 0..* |

**Outgoing References (Encounter references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| subject | Patient, Group | 0..1 |
| episodeOfCare | EpisodeOfCare | 0..* |
| basedOn | ServiceRequest | 0..* |
| participant.individual | Practitioner, PractitionerRole, RelatedPerson | 0..1 |
| appointment | Appointment | 0..* |
| reasonReference | Condition, Procedure, Observation, ImmunizationRecommendation | 0..* |
| diagnosis.condition | Condition, Procedure | 1..1 |
| account | Account | 0..* |
| hospitalization.origin | Location, Organization | 0..1 |
| hospitalization.destination | Location, Organization | 0..1 |
| location.location | Location | 1..1 |
| serviceProvider | Organization | 0..1 |
| partOf | Encounter | 0..1 |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| CareTeam | encounter |
| CarePlan | encounter |
| Condition | encounter |
| Procedure | encounter |
| Observation | encounter |
| MedicationRequest | encounter |
| MedicationAdministration | context |
| MedicationDispense | context |
| ServiceRequest | encounter |
| Task | encounter |
| Communication | encounter |
| Flag | encounter |
| Claim | item.encounter |
| QuestionnaireResponse | encounter |
| DocumentReference | context.encounter |
| AllergyIntolerance | encounter |
| NutritionOrder | encounter |
| Composition | encounter |

---

## 3. EpisodeOfCare

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| type | CodeableConcept | 0..* |
| period | Period | 0..1 |
| statusHistory | BackboneElement | 0..* |
| diagnosis | BackboneElement | 0..* |

**Outgoing References (EpisodeOfCare references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| patient | Patient | 1..1 |
| managingOrganization | Organization | 0..1 |
| referralRequest | ServiceRequest | 0..* |
| careManager | Practitioner, PractitionerRole | 0..1 |
| team | CareTeam | 0..* |
| account | Account | 0..* |
| diagnosis.condition | Condition | 1..1 |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Encounter | episodeOfCare |
| MedicationAdministration | context |
| MedicationDispense | context |
| DocumentReference | context.encounter |

---

## 4. Location

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 0..1 |
| operationalStatus | Coding | 0..1 |
| name | string | 0..1 |
| alias | string | 0..* |
| description | string | 0..1 |
| mode | code | 0..1 |
| type | CodeableConcept | 0..* |
| telecom | ContactPoint | 0..* |
| address | Address | 0..1 |
| physicalType | CodeableConcept | 0..1 |
| position | BackboneElement (longitude, latitude, altitude) | 0..1 |

**Outgoing References (Location references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| managingOrganization | Organization | 0..1 |
| partOf | Location | 0..1 |
| endpoint | Endpoint | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Encounter | location.location, hospitalization.origin, hospitalization.destination |
| PractitionerRole | location |
| CarePlan | activity.detail.location |
| Procedure | location |
| Observation | subject |
| MedicationDispense | location, destination |
| ServiceRequest | locationReference, subject |
| Task | location |
| Appointment | participant.actor |
| Schedule | actor |
| Device | location |
| DeviceRequest | subject |
| SupplyRequest | deliverFrom, deliverTo |
| SupplyDelivery | destination |
| Flag | subject |
| Claim | facility, accident.locationReference |
| Provenance | location |

---

## 5. Organization

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| active | boolean | 0..1 |
| type | CodeableConcept | 0..* |
| name | string | 0..1 |
| alias | string | 0..* |
| telecom | ContactPoint | 0..* |
| address | Address | 0..* |

**Outgoing References (Organization references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| partOf | Organization | 0..1 |
| endpoint | Endpoint | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Patient | generalPractitioner, managingOrganization, contact.organization |
| Encounter | hospitalization.origin, hospitalization.destination, serviceProvider |
| EpisodeOfCare | managingOrganization |
| Location | managingOrganization |
| Practitioner | qualification.issuer |
| PractitionerRole | organization |
| CareTeam | participant.member, participant.onBehalfOf, managingOrganization |
| CarePlan | author, contributor, activity.detail.performer |
| Procedure | performer.actor, performer.onBehalfOf |
| Observation | performer |
| MedicationRequest | requester, performer, reportedReference, dispenseRequest.performer |
| MedicationDispense | performer.actor |
| ServiceRequest | requester, performer |
| Task | requester, owner |
| Device | owner |
| DeviceRequest | requester, performer |
| SupplyRequest | requester, supplier, deliverFrom, deliverTo |
| SupplyDelivery | supplier |
| Communication | recipient, sender |
| Flag | subject, author |
| Consent | organization, performer, provision.actor.reference |
| Coverage | policyHolder, payor |
| Claim | insurer, provider, careTeam.provider, payee.party |
| QuestionnaireResponse | author |
| DocumentReference | author, authenticator, custodian |
| MessageHeader | destination.receiver, sender, responsible |
| Provenance | agent.who, agent.onBehalfOf |
| Goal | subject |
| Composition | author, attester.party, custodian, section.author |

---

## 6. Practitioner

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| active | boolean | 0..1 |
| name | HumanName | 0..* |
| telecom | ContactPoint | 0..* |
| address | Address | 0..* |
| gender | code | 0..1 |
| birthDate | date | 0..1 |
| photo | Attachment | 0..* |
| qualification | BackboneElement | 0..* |
| communication | CodeableConcept | 0..* |

**Outgoing References (Practitioner references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| qualification.issuer | Organization | 0..1 |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Patient | generalPractitioner |
| Encounter | participant.individual |
| EpisodeOfCare | careManager |
| PractitionerRole | practitioner |
| CareTeam | participant.member |
| CarePlan | author, contributor, activity.detail.performer |
| Condition | recorder, asserter |
| Procedure | recorder, asserter, performer.actor |
| Observation | performer |
| MedicationRequest | requester, performer, recorder, reportedReference |
| MedicationAdministration | performer.actor |
| MedicationDispense | performer.actor, receiver, substitution.responsibleParty |
| ServiceRequest | requester, performer |
| Task | requester, owner |
| Appointment | participant.actor |
| Schedule | actor |
| DeviceRequest | requester, performer |
| SupplyRequest | requester |
| SupplyDelivery | supplier, receiver |
| Communication | recipient, sender |
| Flag | subject, author |
| Consent | performer, provision.actor.reference |
| Claim | enterer, provider, careTeam.provider, payee.party |
| QuestionnaireResponse | author, source |
| DocumentReference | subject, author, authenticator |
| MessageHeader | destination.receiver, sender, enterer, author, responsible |
| Provenance | agent.who, agent.onBehalfOf |
| AllergyIntolerance | recorder, asserter |
| Goal | expressedBy |
| NutritionOrder | orderer |
| Composition | author, attester.party, section.author |

---

## 7. PractitionerRole

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| active | boolean | 0..1 |
| period | Period | 0..1 |
| code | CodeableConcept | 0..* |
| specialty | CodeableConcept | 0..* |
| telecom | ContactPoint | 0..* |
| availableTime | BackboneElement | 0..* |
| notAvailable | BackboneElement | 0..* |
| availabilityExceptions | string | 0..1 |

**Outgoing References (PractitionerRole references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| practitioner | Practitioner | 0..1 |
| organization | Organization | 0..1 |
| location | Location | 0..* |
| healthcareService | HealthcareService | 0..* |
| endpoint | Endpoint | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Patient | generalPractitioner |
| Encounter | participant.individual |
| EpisodeOfCare | careManager |
| CareTeam | participant.member |
| CarePlan | author, contributor, activity.detail.performer |
| Condition | recorder, asserter |
| Procedure | recorder, asserter, performer.actor |
| Observation | performer |
| MedicationRequest | requester, performer, recorder, reportedReference |
| MedicationAdministration | performer.actor |
| MedicationDispense | performer.actor, substitution.responsibleParty |
| ServiceRequest | requester, performer |
| Task | requester, owner |
| Appointment | participant.actor |
| Schedule | actor |
| DeviceRequest | requester, performer |
| SupplyRequest | requester |
| SupplyDelivery | supplier, receiver |
| Communication | recipient, sender |
| Flag | author |
| Consent | performer, provision.actor.reference |
| Claim | enterer, provider, careTeam.provider, payee.party |
| QuestionnaireResponse | author, source |
| DocumentReference | author, authenticator |
| MessageHeader | destination.receiver, sender, enterer, author, responsible |
| Provenance | agent.who, agent.onBehalfOf |
| AllergyIntolerance | recorder, asserter |
| Goal | expressedBy |
| NutritionOrder | orderer |
| Composition | author, attester.party, section.author |

---

## 8. CareTeam

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 0..1 |
| category | CodeableConcept | 0..* |
| name | string | 0..1 |
| period | Period | 0..1 |
| reasonCode | CodeableConcept | 0..* |
| telecom | ContactPoint | 0..* |
| note | Annotation | 0..* |

**Outgoing References (CareTeam references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| subject | Patient, Group | 0..1 |
| encounter | Encounter | 0..1 |
| participant.member | Practitioner, PractitionerRole, RelatedPerson, Patient, Organization, CareTeam | 0..1 |
| participant.onBehalfOf | Organization | 0..1 |
| reasonReference | Condition | 0..* |
| managingOrganization | Organization | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| EpisodeOfCare | team |
| CarePlan | careTeam, author, contributor, activity.detail.performer |
| Observation | performer |
| MedicationRequest | performer |
| ServiceRequest | performer |
| Task | owner |
| Consent | provision.actor.reference |
| CareTeam | participant.member |

---

## 9. CarePlan

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| intent | code | 1..1 |
| category | CodeableConcept | 0..* |
| title | string | 0..1 |
| description | string | 0..1 |
| period | Period | 0..1 |
| created | dateTime | 0..1 |
| note | Annotation | 0..* |

**Outgoing References (CarePlan references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| subject | Patient, Group | 1..1 |
| encounter | Encounter | 0..1 |
| author | Patient, Practitioner, PractitionerRole, Device, RelatedPerson, Organization, CareTeam | 0..1 |
| contributor | Patient, Practitioner, PractitionerRole, Device, RelatedPerson, Organization, CareTeam | 0..* |
| careTeam | CareTeam | 0..* |
| addresses | Condition | 0..* |
| supportingInfo | Any | 0..* |
| goal | Goal | 0..* |
| basedOn | CarePlan | 0..* |
| replaces | CarePlan | 0..* |
| partOf | CarePlan | 0..* |
| activity.reference | Appointment, CommunicationRequest, DeviceRequest, MedicationRequest, NutritionOrder, Task, ServiceRequest, VisionPrescription, RequestGroup | 0..1 |
| activity.detail.reasonReference | Condition, Observation, DiagnosticReport, DocumentReference | 0..* |
| activity.detail.goal | Goal | 0..* |
| activity.detail.location | Location | 0..1 |
| activity.detail.performer | Practitioner, PractitionerRole, Organization, RelatedPerson, Patient, CareTeam, HealthcareService, Device | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| CarePlan | basedOn, replaces, partOf |
| Procedure | basedOn |
| Observation | basedOn |
| MedicationRequest | basedOn |
| ServiceRequest | basedOn |
| QuestionnaireResponse | basedOn |

---

## 10. Condition

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| clinicalStatus | CodeableConcept | 0..1 |
| verificationStatus | CodeableConcept | 0..1 |
| category | CodeableConcept | 0..* |
| severity | CodeableConcept | 0..1 |
| code | CodeableConcept | 0..1 |
| bodySite | CodeableConcept | 0..* |
| onset[x] | dateTime / Age / Period / Range / string | 0..1 |
| abatement[x] | dateTime / Age / Period / Range / string | 0..1 |
| recordedDate | dateTime | 0..1 |
| note | Annotation | 0..* |

**Outgoing References (Condition references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| subject | Patient, Group | 1..1 |
| encounter | Encounter | 0..1 |
| recorder | Practitioner, PractitionerRole, Patient, RelatedPerson | 0..1 |
| asserter | Practitioner, PractitionerRole, Patient, RelatedPerson | 0..1 |
| stage.assessment | ClinicalImpression, DiagnosticReport, Observation | 0..* |
| evidence.detail | Any | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Encounter | reasonReference, diagnosis.condition |
| EpisodeOfCare | diagnosis.condition |
| CareTeam | reasonReference |
| CarePlan | addresses, activity.detail.reasonReference |
| Procedure | reasonReference, complicationDetail |
| Observation | (via focus, Any) |
| MedicationRequest | reasonReference |
| MedicationAdministration | reasonReference |
| ServiceRequest | reasonReference |
| Communication | reasonReference |
| Appointment | reasonReference |
| DeviceRequest | reasonReference |
| SupplyRequest | reasonReference |
| Flag | subject |
| Claim | diagnosis.diagnosisReference |
| Goal | addresses |

---

## 11. Procedure

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| statusReason | CodeableConcept | 0..1 |
| category | CodeableConcept | 0..1 |
| code | CodeableConcept | 0..1 |
| performed[x] | dateTime / Period / string / Age / Range | 0..1 |
| reasonCode | CodeableConcept | 0..* |
| bodySite | CodeableConcept | 0..* |
| outcome | CodeableConcept | 0..1 |
| note | Annotation | 0..* |

**Outgoing References (Procedure references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| subject | Patient, Group | 1..1 |
| encounter | Encounter | 0..1 |
| basedOn | CarePlan, ServiceRequest | 0..* |
| partOf | Procedure, Observation, MedicationAdministration | 0..* |
| recorder | Patient, RelatedPerson, Practitioner, PractitionerRole | 0..1 |
| asserter | Patient, RelatedPerson, Practitioner, PractitionerRole | 0..1 |
| performer.actor | Practitioner, PractitionerRole, Organization, Patient, RelatedPerson, Device | 1..1 |
| performer.onBehalfOf | Organization | 0..1 |
| location | Location | 0..1 |
| reasonReference | Condition, Observation, Procedure, DiagnosticReport, DocumentReference | 0..* |
| report | DiagnosticReport, DocumentReference, Composition | 0..* |
| complicationDetail | Condition | 0..* |
| focalDevice.manipulated | Device | 1..1 |
| usedReference | Device, Medication, Substance | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Encounter | reasonReference, diagnosis.condition |
| Procedure | partOf, reasonReference |
| Observation | partOf |
| MedicationAdministration | partOf |
| MedicationDispense | partOf |
| QuestionnaireResponse | partOf |
| Flag | subject |
| Claim | procedure.procedureReference |

---

## 12. Observation

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| category | CodeableConcept | 0..* |
| code | CodeableConcept | 1..1 |
| effective[x] | dateTime / Period / Timing / instant | 0..1 |
| issued | instant | 0..1 |
| value[x] | Quantity / CodeableConcept / string / boolean / integer / Range / Ratio / SampledData / time / dateTime / Period | 0..1 |
| dataAbsentReason | CodeableConcept | 0..1 |
| interpretation | CodeableConcept | 0..* |
| bodySite | CodeableConcept | 0..1 |
| method | CodeableConcept | 0..1 |
| note | Annotation | 0..* |
| component | BackboneElement | 0..* |

**Outgoing References (Observation references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| basedOn | CarePlan, DeviceRequest, ImmunizationRecommendation, MedicationRequest, NutritionOrder, ServiceRequest | 0..* |
| partOf | MedicationAdministration, MedicationDispense, MedicationStatement, Procedure, Immunization, ImagingStudy | 0..* |
| subject | Patient, Group, Device, Location | 0..1 |
| focus | Any | 0..* |
| encounter | Encounter | 0..1 |
| performer | Practitioner, PractitionerRole, Organization, CareTeam, Patient, RelatedPerson | 0..* |
| specimen | Specimen | 0..1 |
| device | Device, DeviceMetric | 0..1 |
| hasMember | Observation, QuestionnaireResponse, MolecularSequence | 0..* |
| derivedFrom | DocumentReference, ImagingStudy, Media, QuestionnaireResponse, Observation, MolecularSequence | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Encounter | reasonReference |
| Condition | stage.assessment |
| Procedure | partOf, reasonReference |
| Observation | hasMember, derivedFrom |
| MedicationRequest | reasonReference |
| MedicationAdministration | reasonReference |
| ServiceRequest | reasonReference |
| Communication | reasonReference |
| Appointment | reasonReference |
| CarePlan | activity.detail.reasonReference |
| DeviceRequest | reasonReference |
| SupplyRequest | reasonReference |
| Goal | addresses, outcomeReference |

---

## 13. MedicationRequest

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| statusReason | CodeableConcept | 0..1 |
| intent | code | 1..1 |
| category | CodeableConcept | 0..* |
| priority | code | 0..1 |
| doNotPerform | boolean | 0..1 |
| medication[x] | CodeableConcept / Reference(Medication) | 1..1 |
| authoredOn | dateTime | 0..1 |
| reasonCode | CodeableConcept | 0..* |
| dosageInstruction | Dosage | 0..* |
| note | Annotation | 0..* |

**Outgoing References (MedicationRequest references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| subject | Patient, Group | 1..1 |
| encounter | Encounter | 0..1 |
| requester | Practitioner, PractitionerRole, Organization, Patient, RelatedPerson, Device | 0..1 |
| performer | Practitioner, PractitionerRole, Organization, Patient, Device, RelatedPerson, CareTeam | 0..1 |
| recorder | Practitioner, PractitionerRole | 0..1 |
| reasonReference | Condition, Observation | 0..* |
| basedOn | CarePlan, MedicationRequest, ServiceRequest, ImmunizationRecommendation | 0..* |
| insurance | Coverage, ClaimResponse | 0..* |
| priorPrescription | MedicationRequest | 0..1 |
| reportedReference | Patient, Practitioner, PractitionerRole, RelatedPerson, Organization | 0..1 |
| medicationReference | Medication | 1..1 |
| dispenseRequest.performer | Organization | 0..1 |
| supportingInformation | Any | 0..* |
| detectedIssue | DetectedIssue | 0..* |
| eventHistory | Provenance | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| MedicationRequest | basedOn, priorPrescription |
| MedicationAdministration | request |
| MedicationDispense | authorizingPrescription |
| Observation | basedOn |
| CarePlan | activity.reference |
| ServiceRequest | basedOn |
| Claim | prescription, originalPrescription |

---

## 14. MedicationAdministration

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| statusReason | CodeableConcept | 0..* |
| category | CodeableConcept | 0..1 |
| medication[x] | CodeableConcept / Reference(Medication) | 1..1 |
| effective[x] | dateTime / Period | 1..1 |
| reasonCode | CodeableConcept | 0..* |
| dosage | BackboneElement | 0..1 |
| note | Annotation | 0..* |

**Outgoing References (MedicationAdministration references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| partOf | MedicationAdministration, Procedure | 0..* |
| subject | Patient, Group | 1..1 |
| context | Encounter, EpisodeOfCare | 0..1 |
| supportingInformation | Any | 0..* |
| performer.actor | Practitioner, PractitionerRole, Patient, RelatedPerson, Device | 1..1 |
| reasonReference | Condition, Observation, DiagnosticReport | 0..* |
| request | MedicationRequest | 0..1 |
| device | Device | 0..* |
| eventHistory | Provenance | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Procedure | partOf |
| Observation | partOf |
| MedicationAdministration | partOf |

---

## 15. MedicationDispense

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| category | CodeableConcept | 0..1 |
| medication[x] | CodeableConcept / Reference(Medication) | 1..1 |
| type | CodeableConcept | 0..1 |
| quantity | SimpleQuantity | 0..1 |
| daysSupply | SimpleQuantity | 0..1 |
| whenPrepared | dateTime | 0..1 |
| whenHandedOver | dateTime | 0..1 |
| dosageInstruction | Dosage | 0..* |
| note | Annotation | 0..* |

**Outgoing References (MedicationDispense references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| partOf | Procedure | 0..* |
| subject | Patient, Group | 0..1 |
| context | Encounter, EpisodeOfCare | 0..1 |
| supportingInformation | Any | 0..* |
| performer.actor | Practitioner, PractitionerRole, Organization, Patient, Device, RelatedPerson | 1..1 |
| location | Location | 0..1 |
| authorizingPrescription | MedicationRequest | 0..* |
| destination | Location | 0..1 |
| receiver | Patient, Practitioner | 0..* |
| substitution.responsibleParty | Practitioner, PractitionerRole | 0..* |
| detectedIssue | DetectedIssue | 0..* |
| eventHistory | Provenance | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Observation | partOf |

---

## 16. ServiceRequest

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| intent | code | 1..1 |
| category | CodeableConcept | 0..* |
| priority | code | 0..1 |
| doNotPerform | boolean | 0..1 |
| code | CodeableConcept | 0..1 |
| subject | Reference(Patient, Group, Location, Device) | 1..1 |
| occurrence[x] | dateTime / Period / Timing | 0..1 |
| authoredOn | dateTime | 0..1 |
| reasonCode | CodeableConcept | 0..* |
| bodySite | CodeableConcept | 0..* |
| note | Annotation | 0..* |

**Outgoing References (ServiceRequest references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| basedOn | CarePlan, ServiceRequest, MedicationRequest | 0..* |
| replaces | ServiceRequest | 0..* |
| encounter | Encounter | 0..1 |
| requester | Practitioner, PractitionerRole, Organization, Patient, RelatedPerson, Device | 0..1 |
| performer | Practitioner, PractitionerRole, Organization, CareTeam, HealthcareService, Patient, Device, RelatedPerson | 0..* |
| locationReference | Location | 0..* |
| reasonReference | Condition, Observation, DiagnosticReport, DocumentReference | 0..* |
| insurance | Coverage, ClaimResponse | 0..* |
| supportingInfo | Any | 0..* |
| specimen | Specimen | 0..* |
| relevantHistory | Provenance | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Encounter | basedOn |
| EpisodeOfCare | referralRequest |
| Procedure | basedOn |
| Observation | basedOn |
| MedicationRequest | basedOn |
| ServiceRequest | basedOn, replaces |
| Appointment | basedOn |
| CarePlan | activity.reference |
| Claim | referral |
| QuestionnaireResponse | basedOn |
| Goal | addresses |

---

## 17. Task

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| statusReason | CodeableConcept | 0..1 |
| businessStatus | CodeableConcept | 0..1 |
| intent | code | 1..1 |
| priority | code | 0..1 |
| code | CodeableConcept | 0..1 |
| description | string | 0..1 |
| executionPeriod | Period | 0..1 |
| authoredOn | dateTime | 0..1 |
| lastModified | dateTime | 0..1 |
| note | Annotation | 0..* |
| input | BackboneElement | 0..* |
| output | BackboneElement | 0..* |

**Outgoing References (Task references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| basedOn | Any | 0..* |
| partOf | Task | 0..* |
| focus | Any | 0..1 |
| for | Any | 0..1 |
| encounter | Encounter | 0..1 |
| requester | Device, Organization, Patient, Practitioner, PractitionerRole, RelatedPerson | 0..1 |
| owner | Practitioner, PractitionerRole, Organization, CareTeam, HealthcareService, Patient, Device, RelatedPerson | 0..1 |
| location | Location | 0..1 |
| reasonReference | Any | 0..1 |
| insurance | Coverage, ClaimResponse | 0..* |
| relevantHistory | Provenance | 0..* |
| restriction.recipient | Patient, Practitioner, PractitionerRole, RelatedPerson, Group, Organization | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Task | partOf |
| CarePlan | activity.reference |

---

## 18. Appointment

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| cancelationReason | CodeableConcept | 0..1 |
| serviceCategory | CodeableConcept | 0..* |
| serviceType | CodeableConcept | 0..* |
| specialty | CodeableConcept | 0..* |
| appointmentType | CodeableConcept | 0..1 |
| reasonCode | CodeableConcept | 0..* |
| priority | unsignedInt | 0..1 |
| description | string | 0..1 |
| start | instant | 0..1 |
| end | instant | 0..1 |
| minutesDuration | positiveInt | 0..1 |
| created | dateTime | 0..1 |
| comment | string | 0..1 |
| requestedPeriod | Period | 0..* |

**Outgoing References (Appointment references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| reasonReference | Condition, Procedure, Observation, ImmunizationRecommendation | 0..* |
| supportingInformation | Any | 0..* |
| basedOn | ServiceRequest | 0..* |
| slot | Slot | 0..* |
| participant.actor | Patient, Practitioner, PractitionerRole, RelatedPerson, Device, HealthcareService, Location | 0..1 |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Encounter | appointment |
| CarePlan | activity.reference |

---

## 19. Schedule

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| active | boolean | 0..1 |
| serviceCategory | CodeableConcept | 0..* |
| serviceType | CodeableConcept | 0..* |
| specialty | CodeableConcept | 0..* |
| planningHorizon | Period | 0..1 |
| comment | string | 0..1 |

**Outgoing References (Schedule references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| actor | Patient, Practitioner, PractitionerRole, RelatedPerson, Device, HealthcareService, Location | 1..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Slot | schedule |

---

## 20. Slot

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| serviceCategory | CodeableConcept | 0..* |
| serviceType | CodeableConcept | 0..* |
| specialty | CodeableConcept | 0..* |
| appointmentType | CodeableConcept | 0..1 |
| status | code | 1..1 |
| start | instant | 1..1 |
| end | instant | 1..1 |
| overbooked | boolean | 0..1 |
| comment | string | 0..1 |

**Outgoing References (Slot references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| schedule | Schedule | 1..1 |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Appointment | slot |

---

## 21. Device

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 0..1 |
| statusReason | CodeableConcept | 0..* |
| manufacturer | string | 0..1 |
| manufactureDate | dateTime | 0..1 |
| expirationDate | dateTime | 0..1 |
| lotNumber | string | 0..1 |
| serialNumber | string | 0..1 |
| modelNumber | string | 0..1 |
| type | CodeableConcept | 0..1 |
| note | Annotation | 0..* |
| safety | CodeableConcept | 0..* |
| udiCarrier | BackboneElement | 0..* |
| deviceName | BackboneElement | 0..* |

**Outgoing References (Device references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| definition | DeviceDefinition | 0..1 |
| patient | Patient | 0..1 |
| owner | Organization | 0..1 |
| location | Location | 0..1 |
| parent | Device | 0..1 |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Procedure | performer.actor, focalDevice.manipulated, usedReference |
| Observation | subject, device |
| MedicationAdministration | performer.actor, device |
| MedicationDispense | performer.actor |
| MedicationRequest | requester |
| ServiceRequest | requester, performer, subject |
| Task | requester, owner |
| Appointment | participant.actor |
| Schedule | actor |
| DeviceRequest | code[x], requester, performer, subject |
| SupplyRequest | requester, item[x] |
| Communication | recipient, sender |
| Flag | author |
| Consent | provision.actor.reference |
| Claim | procedure.udi, item.udi, item.detail.udi, item.detail.subDetail.udi |
| QuestionnaireResponse | author |
| DocumentReference | subject, author |
| MessageHeader | destination.target |
| Provenance | agent.who, agent.onBehalfOf |
| CarePlan | author, contributor, activity.detail.performer |
| Composition | author, section.author |
| Device | parent |

---

## 22. DeviceRequest

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 0..1 |
| intent | code | 1..1 |
| priority | code | 0..1 |
| code[x] | Reference(Device) / CodeableConcept | 1..1 |
| authoredOn | dateTime | 0..1 |
| performerType | CodeableConcept | 0..1 |
| reasonCode | CodeableConcept | 0..* |
| note | Annotation | 0..* |

**Outgoing References (DeviceRequest references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| basedOn | Any | 0..* |
| priorRequest | Any | 0..* |
| subject | Patient, Group, Location, Device | 1..1 |
| encounter | Encounter | 0..1 |
| requester | Device, Practitioner, PractitionerRole, Organization | 0..1 |
| performer | Practitioner, PractitionerRole, Organization, CareTeam, HealthcareService, Patient, Device, RelatedPerson | 0..1 |
| reasonReference | Condition, Observation, DiagnosticReport, DocumentReference | 0..* |
| insurance | Coverage, ClaimResponse | 0..* |
| supportingInfo | Any | 0..* |
| relevantHistory | Provenance | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Observation | basedOn |
| CarePlan | activity.reference |
| Claim | prescription, originalPrescription |

---

## 23. SupplyRequest

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 0..1 |
| category | CodeableConcept | 0..1 |
| priority | code | 0..1 |
| item[x] | CodeableConcept / Reference(Medication, Substance, Device) | 1..1 |
| quantity | Quantity | 1..1 |
| occurrence[x] | dateTime / Period / Timing | 0..1 |
| authoredOn | dateTime | 0..1 |
| reasonCode | CodeableConcept | 0..* |

**Outgoing References (SupplyRequest references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| requester | Practitioner, PractitionerRole, Organization, Patient, RelatedPerson, Device | 0..1 |
| supplier | Organization, HealthcareService | 0..* |
| reasonReference | Condition, Observation, DiagnosticReport, DocumentReference | 0..* |
| deliverFrom | Organization, Location | 0..1 |
| deliverTo | Organization, Location, Patient | 0..1 |
| itemReference | Medication, Substance, Device | 1..1 |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| SupplyDelivery | basedOn |

---

## 24. SupplyDelivery

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 0..1 |
| type | CodeableConcept | 0..1 |
| occurrence[x] | dateTime / Period / Timing | 0..1 |
| suppliedItem.quantity | SimpleQuantity | 0..1 |
| suppliedItem.item[x] | CodeableConcept / Reference(Medication, Substance, Device) | 0..1 |

**Outgoing References (SupplyDelivery references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| basedOn | SupplyRequest | 0..* |
| partOf | SupplyDelivery, Contract | 0..* |
| patient | Patient | 0..1 |
| supplier | Practitioner, PractitionerRole, Organization | 0..1 |
| destination | Location | 0..1 |
| receiver | Practitioner, PractitionerRole | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| SupplyDelivery | partOf |

---

## 25. Communication

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| statusReason | CodeableConcept | 0..1 |
| category | CodeableConcept | 0..* |
| priority | code | 0..1 |
| medium | CodeableConcept | 0..* |
| topic | CodeableConcept | 0..1 |
| sent | dateTime | 0..1 |
| received | dateTime | 0..1 |
| reasonCode | CodeableConcept | 0..* |
| payload | BackboneElement | 0..* |
| note | Annotation | 0..* |

**Outgoing References (Communication references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| basedOn | Any | 0..* |
| partOf | Any | 0..* |
| inResponseTo | Communication | 0..* |
| subject | Patient, Group | 0..1 |
| about | Any | 0..* |
| encounter | Encounter | 0..1 |
| recipient | Device, Organization, Patient, Practitioner, PractitionerRole, RelatedPerson, Group, CareTeam, HealthcareService | 0..* |
| sender | Device, Organization, Patient, Practitioner, PractitionerRole, RelatedPerson, HealthcareService | 0..1 |
| reasonReference | Condition, Observation, DiagnosticReport, DocumentReference | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Communication | inResponseTo |

---

## 26. Flag

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| category | CodeableConcept | 0..* |
| code | CodeableConcept | 1..1 |
| period | Period | 0..1 |

**Outgoing References (Flag references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| subject | Patient, Location, Group, Organization, Practitioner, PlanDefinition, Medication, Procedure | 1..1 |
| encounter | Encounter | 0..1 |
| author | Device, Organization, Patient, Practitioner, PractitionerRole | 0..1 |

**Incoming References (referenced BY):**

(No resources in this set directly reference Flag.)

---

## 27. Consent

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| scope | CodeableConcept | 1..1 |
| category | CodeableConcept | 1..* |
| dateTime | dateTime | 0..1 |
| policyRule | CodeableConcept | 0..1 |
| provision.type | code | 0..1 |
| provision.period | Period | 0..1 |
| provision.action | CodeableConcept | 0..* |
| provision.securityLabel | Coding | 0..* |
| provision.purpose | Coding | 0..* |
| verification.verified | boolean | 1..1 |

**Outgoing References (Consent references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| patient | Patient | 0..1 |
| performer | Organization, Patient, Practitioner, RelatedPerson, PractitionerRole | 0..* |
| organization | Organization | 0..* |
| sourceReference | Consent, DocumentReference, Contract, QuestionnaireResponse | 0..1 |
| provision.actor.reference | Device, Group, CareTeam, Organization, Patient, Practitioner, RelatedPerson, PractitionerRole | 1..1 |
| provision.data.reference | Any | 1..1 |
| verification.verifiedWith | Patient, RelatedPerson | 0..1 |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Consent | sourceReference |

---

## 28. Coverage

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| type | CodeableConcept | 0..1 |
| subscriberId | string | 0..1 |
| dependent | string | 0..1 |
| relationship | CodeableConcept | 0..1 |
| period | Period | 0..1 |
| order | positiveInt | 0..1 |
| network | string | 0..1 |
| class | BackboneElement | 0..* |
| costToBeneficiary | BackboneElement | 0..* |

**Outgoing References (Coverage references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| policyHolder | Patient, RelatedPerson, Organization | 0..1 |
| subscriber | Patient, RelatedPerson | 0..1 |
| beneficiary | Patient | 1..1 |
| payor | Organization, Patient, RelatedPerson | 1..* |
| contract | Contract | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| MedicationRequest | insurance |
| ServiceRequest | insurance |
| Task | insurance |
| DeviceRequest | insurance |
| Claim | insurance.coverage |

---

## 29. Claim

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| type | CodeableConcept | 1..1 |
| subType | CodeableConcept | 0..1 |
| use | code | 1..1 |
| billablePeriod | Period | 0..1 |
| created | dateTime | 1..1 |
| priority | CodeableConcept | 1..1 |
| total | Money | 0..1 |

**Outgoing References (Claim references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| patient | Patient | 1..1 |
| enterer | Practitioner, PractitionerRole | 0..1 |
| insurer | Organization | 0..1 |
| provider | Practitioner, PractitionerRole, Organization | 1..1 |
| related.claim | Claim | 0..1 |
| prescription | DeviceRequest, MedicationRequest, VisionPrescription | 0..1 |
| originalPrescription | DeviceRequest, MedicationRequest, VisionPrescription | 0..1 |
| payee.party | Practitioner, PractitionerRole, Organization, Patient, RelatedPerson | 0..1 |
| referral | ServiceRequest | 0..1 |
| facility | Location | 0..1 |
| careTeam.provider | Practitioner, PractitionerRole, Organization | 1..1 |
| diagnosis.diagnosisReference | Condition | 0..1 |
| procedure.procedureReference | Procedure | 0..1 |
| procedure.udi | Device | 0..* |
| insurance.coverage | Coverage | 1..1 |
| insurance.claimResponse | ClaimResponse | 0..1 |
| accident.locationReference | Location | 0..1 |
| item.udi | Device | 0..* |
| item.encounter | Encounter | 0..* |
| item.detail.udi | Device | 0..* |
| item.detail.subDetail.udi | Device | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Claim | related.claim |

---

## 30. QuestionnaireResponse

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..1 |
| questionnaire | canonical(Questionnaire) | 0..1 |
| status | code | 1..1 |
| authored | dateTime | 0..1 |
| item | BackboneElement (nested) | 0..* |

**Outgoing References (QuestionnaireResponse references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| basedOn | CarePlan, ServiceRequest | 0..* |
| partOf | Observation, Procedure | 0..* |
| subject | Any | 0..1 |
| encounter | Encounter | 0..1 |
| author | Device, Practitioner, PractitionerRole, Patient, RelatedPerson, Organization | 0..1 |
| source | Patient, Practitioner, PractitionerRole, RelatedPerson | 0..1 |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Observation | hasMember, derivedFrom |
| Consent | sourceReference |

---

## 31. DocumentReference

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| masterIdentifier | Identifier | 0..1 |
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| docStatus | code | 0..1 |
| type | CodeableConcept | 0..1 |
| category | CodeableConcept | 0..* |
| date | instant | 0..1 |
| description | string | 0..1 |
| securityLabel | CodeableConcept | 0..* |
| content.attachment | Attachment | 1..* |
| content.format | Coding | 0..1 |

**Outgoing References (DocumentReference references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| subject | Patient, Practitioner, Group, Device | 0..1 |
| author | Practitioner, PractitionerRole, Organization, Device, Patient, RelatedPerson | 0..* |
| authenticator | Practitioner, PractitionerRole, Organization | 0..1 |
| custodian | Organization | 0..1 |
| relatesTo.target | DocumentReference | 1..1 |
| context.encounter | Encounter, EpisodeOfCare | 0..* |
| context.sourcePatientInfo | Patient | 0..1 |
| context.related | Any | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Procedure | reasonReference, report |
| Observation | derivedFrom |
| ServiceRequest | reasonReference |
| Communication | reasonReference |
| CarePlan | activity.detail.reasonReference |
| DeviceRequest | reasonReference |
| SupplyRequest | reasonReference |
| Consent | sourceReference |
| DocumentReference | relatesTo.target |

---

## 32. MessageHeader

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| event[x] | Coding / uri | 1..1 |
| destination.name | string | 0..1 |
| destination.endpoint | url | 1..1 |
| source.name | string | 0..1 |
| source.software | string | 0..1 |
| source.version | string | 0..1 |
| source.endpoint | url | 1..1 |
| reason | CodeableConcept | 0..1 |
| response.identifier | id | 1..1 |
| response.code | code | 1..1 |

**Outgoing References (MessageHeader references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| destination.target | Device | 0..1 |
| destination.receiver | Practitioner, PractitionerRole, Organization | 0..1 |
| sender | Practitioner, PractitionerRole, Organization | 0..1 |
| enterer | Practitioner, PractitionerRole | 0..1 |
| author | Practitioner, PractitionerRole | 0..1 |
| responsible | Practitioner, PractitionerRole, Organization | 0..1 |
| response.details | OperationOutcome | 0..1 |
| focus | Any | 0..* |

**Incoming References (referenced BY):**

(No resources in this set directly reference MessageHeader.)

---

## 33. Provenance

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| recorded | instant | 1..1 |
| occurred[x] | Period / dateTime | 0..1 |
| policy | uri | 0..* |
| reason | CodeableConcept | 0..* |
| activity | CodeableConcept | 0..1 |
| agent.type | CodeableConcept | 0..1 |
| agent.role | CodeableConcept | 0..* |
| entity.role | code | 1..1 |
| signature | Signature | 0..* |

**Outgoing References (Provenance references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| target | Any | 1..* |
| location | Location | 0..1 |
| agent.who | Practitioner, PractitionerRole, RelatedPerson, Patient, Device, Organization | 1..1 |
| agent.onBehalfOf | Practitioner, PractitionerRole, RelatedPerson, Patient, Device, Organization | 0..1 |
| entity.what | Any | 1..1 |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| MedicationRequest | eventHistory |
| MedicationAdministration | eventHistory |
| MedicationDispense | eventHistory |
| ServiceRequest | relevantHistory |
| Task | relevantHistory |
| DeviceRequest | relevantHistory |

---

## 34. AllergyIntolerance

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| clinicalStatus | CodeableConcept | 0..1 |
| verificationStatus | CodeableConcept | 0..1 |
| type | code | 0..1 |
| category | code | 0..* |
| criticality | code | 0..1 |
| code | CodeableConcept | 0..1 |
| onset[x] | dateTime / Age / Period / Range / string | 0..1 |
| recordedDate | dateTime | 0..1 |
| lastOccurrence | dateTime | 0..1 |
| note | Annotation | 0..* |
| reaction | BackboneElement | 0..* |

**Outgoing References (AllergyIntolerance references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| patient | Patient | 1..1 |
| encounter | Encounter | 0..1 |
| recorder | Practitioner, PractitionerRole, Patient, RelatedPerson | 0..1 |
| asserter | Patient, RelatedPerson, Practitioner, PractitionerRole | 0..1 |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| NutritionOrder | allergyIntolerance |

---

## 35. Goal

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| lifecycleStatus | code | 1..1 |
| achievementStatus | CodeableConcept | 0..1 |
| category | CodeableConcept | 0..* |
| priority | CodeableConcept | 0..1 |
| description | CodeableConcept | 1..1 |
| start[x] | date / CodeableConcept | 0..1 |
| statusDate | date | 0..1 |
| statusReason | string | 0..1 |
| target | BackboneElement | 0..* |
| note | Annotation | 0..* |
| outcomeCode | CodeableConcept | 0..* |

**Outgoing References (Goal references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| subject | Patient, Group, Organization | 1..1 |
| expressedBy | Patient, Practitioner, PractitionerRole, RelatedPerson | 0..1 |
| addresses | Condition, Observation, MedicationStatement, NutritionOrder, ServiceRequest, RiskAssessment | 0..* |
| outcomeReference | Observation | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| CarePlan | goal, activity.detail.goal |

---

## 36. NutritionOrder

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..* |
| status | code | 1..1 |
| intent | code | 1..1 |
| dateTime | dateTime | 1..1 |
| foodPreferenceModifier | CodeableConcept | 0..* |
| excludeFoodModifier | CodeableConcept | 0..* |
| oralDiet | BackboneElement | 0..1 |
| supplement | BackboneElement | 0..* |
| enteralFormula | BackboneElement | 0..1 |
| note | Annotation | 0..* |

**Outgoing References (NutritionOrder references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| patient | Patient | 1..1 |
| encounter | Encounter | 0..1 |
| orderer | Practitioner, PractitionerRole | 0..1 |
| allergyIntolerance | AllergyIntolerance | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Observation | basedOn |
| CarePlan | activity.reference |
| Goal | addresses |

---

## 37. Composition

**Key Attributes:**

| Attribute | Type | Cardinality |
|---|---|---|
| identifier | Identifier | 0..1 |
| status | code | 1..1 |
| type | CodeableConcept | 1..1 |
| category | CodeableConcept | 0..* |
| date | dateTime | 1..1 |
| title | string | 1..1 |
| confidentiality | code | 0..1 |
| attester.mode | code | 1..1 |
| attester.time | dateTime | 0..1 |
| section.title | string | 0..1 |
| section.code | CodeableConcept | 0..1 |
| section.text | Narrative | 0..1 |

**Outgoing References (Composition references TO):**

| Field | Target Resource | Cardinality |
|---|---|---|
| subject | Any | 0..1 |
| encounter | Encounter | 0..1 |
| author | Practitioner, PractitionerRole, Device, Patient, RelatedPerson, Organization | 1..* |
| attester.party | Patient, RelatedPerson, Practitioner, PractitionerRole, Organization | 0..1 |
| custodian | Organization | 0..1 |
| relatesTo.target[x] | Identifier / Composition | 1..1 |
| event.detail | Any | 0..* |
| section.author | Practitioner, PractitionerRole, Device, Patient, RelatedPerson, Organization | 0..* |
| section.focus | Any | 0..1 |
| section.entry | Any | 0..* |

**Incoming References (referenced BY):**

| Source Resource | Field |
|---|---|
| Procedure | report |
| Composition | relatesTo.target[x] |

---

## 38. Cross-Reference Matrix

### Relationship Summary (within the 37-resource scope)

This matrix shows the **direct reference relationships** between the 37 resources. Read as: Row resource references Column resource.

| FROM \ TO | Patient | Encounter | EpisodeOfCare | Location | Organization | Practitioner | PractitionerRole | CareTeam | CarePlan | Condition | Procedure | Observation | MedicationRequest | MedicationAdmin | MedicationDispense | ServiceRequest | Task | Appointment | Schedule | Slot | Device | DeviceRequest | SupplyRequest | SupplyDelivery | Communication | Flag | Consent | Coverage | Claim | QuestionnaireResp | DocumentRef | MessageHeader | Provenance | AllergyIntolerance | Goal | NutritionOrder | Composition |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Patient** | X | | | | X | X | X | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |
| **Encounter** | X | X | X | X | X | X | X | | | X | X | X | | | | X | | X | | | | | | | | | | | | | | | | | | | |
| **EpisodeOfCare** | X | | | | X | X | X | X | | X | | | | | | X | | | | | | | | | | | | | | | | | | | | | |
| **Location** | | | | X | X | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |
| **Organization** | | | | | X | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |
| **Practitioner** | | | | | X | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |
| **PractitionerRole** | | | | X | X | X | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |
| **CareTeam** | X | X | | | X | X | X | X | | X | | | | | | | | | | | | | | | | | | | | | | | | | | | |
| **CarePlan** | X | X | | X | X | X | X | X | X | X | | X | X | | | X | X | X | | | X | X | | | | | | | | | X | | | | X | X | |
| **Condition** | X | X | | | | X | X | | | | | X | | | | | | | | | | | | | | | | | | | | | | | | | |
| **Procedure** | X | X | | X | X | X | X | | X | X | X | X | | X | | X | | | | | X | | | | | | | | | | X | | | | | | X |
| **Observation** | X | X | | X | | X | X | X | X | | X | X | X | X | X | X | | | | | X | X | | | | | | | | X | X | | | | | X | |
| **MedicationRequest** | X | X | | | X | X | X | X | X | X | | X | X | | | X | | | | | X | | | | | | | X | | | | | X | | | | |
| **MedicationAdmin** | X | X | X | | | X | X | | | X | X | X | X | X | | | | | | | X | | | | | | | | | | | | X | | | | |
| **MedicationDispense** | X | X | X | X | X | X | X | | | | X | | X | | | | | | | | X | | | | | | | | | | | | X | | | | |
| **ServiceRequest** | X | X | | X | X | X | X | X | X | X | | X | X | | | X | | | | | X | | | | | | | X | | | X | | X | | | | |
| **Task** | X | X | | X | X | X | X | X | | | | | | | | | X | | | | X | | | | | | | X | | | | | X | | | | |
| **Appointment** | X | | | X | | X | X | | | X | X | X | | | | X | | | | X | X | | | | | | | | | | | | | | | | |
| **Schedule** | X | | | X | | X | X | | | | | | | | | | | | | | X | | | | | | | | | | | | | | | | |
| **Slot** | | | | | | | | | | | | | | | | | | | X | | | | | | | | | | | | | | | | | | |
| **Device** | X | | | X | X | | | | | | | | | | | | | | | | X | | | | | | | | | | | | | | | | |
| **DeviceRequest** | X | X | | X | X | X | X | X | | X | | X | | | | | | | | | X | | | | | | | X | | | X | | X | | | | |
| **SupplyRequest** | X | | | X | X | X | X | | | X | | X | | | | | | | | | X | | | | | | | | | | X | | | | | | |
| **SupplyDelivery** | X | | | X | X | X | X | | | | | | | | | | | | | | | | X | X | | | | | | | | | | | | | |
| **Communication** | X | X | | | X | X | X | X | | X | | X | | | | | | | | | X | | | | X | | | | | | X | | | | | | |
| **Flag** | X | X | | X | X | X | X | | | | X | | | | | | | | | | X | | | | | | | | | | | | | | | | |
| **Consent** | X | | | | X | X | X | X | | | | | | | | | | | | | X | | | | | | X | | | X | X | | | | | | |
| **Coverage** | X | | | | X | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |
| **Claim** | X | X | | X | X | X | X | | | X | X | | X | | | X | | | | | X | X | | | | | | X | X | | | | | | | | |
| **QuestionnaireResp** | X | X | | | X | X | X | | X | | X | X | | | | X | | | | | X | | | | | | | | | | | | | | | | |
| **DocumentReference** | X | X | X | | X | X | X | | | | | | | | | | | | | | X | | | | | | | | | | X | | | | | | |
| **MessageHeader** | | | | | X | X | X | | | | | | | | | | | | | | X | | | | | | | | | | | | | | | | |
| **Provenance** | X | | | X | X | X | X | | | | | | | | | | | | | | X | | | | | | | | | | | | | | | | |
| **AllergyIntolerance** | X | X | | | | X | X | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |
| **Goal** | X | | | | X | X | X | | | X | | X | | | | X | | | | | | | | | | | | | | | | | | | | X | |
| **NutritionOrder** | X | X | | | | X | X | | | | | | | | | | | | | | | | | | | | | | | | | | | X | | | |
| **Composition** | X | X | | | X | X | X | | | | | | | | | | | | | | X | | | | | | | | | | | | | | | | X |

### Most-Referenced Resources (Hub Resources)

Ranked by number of incoming references from the 37-resource set:

1. **Patient** - Referenced by 33 resources (nearly universal subject/patient field)
2. **Practitioner** - Referenced by 30 resources
3. **PractitionerRole** - Referenced by 29 resources
4. **Organization** - Referenced by 28 resources
5. **Encounter** - Referenced by 19 resources
6. **Device** - Referenced by 19 resources
7. **Location** - Referenced by 17 resources
8. **Condition** - Referenced by 15 resources
9. **Observation** - Referenced by 13 resources
10. **CareTeam** - Referenced by 8 resources
11. **ServiceRequest** - Referenced by 11 resources
12. **Coverage** - Referenced by 5 resources
13. **CarePlan** - Referenced by 6 resources
14. **Procedure** - Referenced by 8 resources
15. **Provenance** - Referenced by 6 resources
16. **MedicationRequest** - Referenced by 7 resources
17. **Goal** - Referenced by 2 resources (CarePlan)
18. **DocumentReference** - Referenced by 9 resources
19. **Appointment** - Referenced by 2 resources (Encounter, CarePlan)
20. **Schedule** - Referenced by 1 resource (Slot)
21. **Slot** - Referenced by 1 resource (Appointment)
22. **AllergyIntolerance** - Referenced by 1 resource (NutritionOrder)
23. **MedicationAdministration** - Referenced by 3 resources
24. **MedicationDispense** - Referenced by 1 resource (Observation)
25. **Composition** - Referenced by 2 resources (Procedure, Composition)
26. **QuestionnaireResponse** - Referenced by 2 resources (Observation, Consent)
27. **SupplyRequest** - Referenced by 1 resource (SupplyDelivery)
28. **NutritionOrder** - Referenced by 3 resources (Observation, CarePlan, Goal)
29. **Communication** - Referenced by 1 resource (Communication self-ref)
30. **Flag** - Referenced by 0 resources (leaf node)
31. **Consent** - Referenced by 1 resource (Consent self-ref)
32. **Claim** - Referenced by 1 resource (Claim self-ref)
33. **MessageHeader** - Referenced by 0 resources (leaf node)
34. **Task** - Referenced by 2 resources (Task, CarePlan)
35. **DeviceRequest** - Referenced by 3 resources (Observation, CarePlan, Claim)
36. **SupplyDelivery** - Referenced by 1 resource (SupplyDelivery self-ref)

### Key Relationship Patterns

**Central Hub: Patient**
- Almost every clinical resource has a `subject` or `patient` field pointing to Patient
- Patient itself references Organization (managing) and Practitioner/PractitionerRole (general practitioner)

**Encounter as Context:**
- Most clinical events (Condition, Procedure, Observation, MedicationRequest, etc.) reference Encounter via `encounter` or `context`
- Encounter references Patient, Location, Organization, Practitioner, ServiceRequest, EpisodeOfCare

**Episode-Encounter Hierarchy:**
- EpisodeOfCare groups multiple Encounters for a patient
- Encounter.episodeOfCare -> EpisodeOfCare (0..*)
- EpisodeOfCare.patient -> Patient (1..1)

**Scheduling Chain:**
- Schedule -> (actors: Practitioner, Location, etc.)
- Slot -> Schedule (1..1)
- Appointment -> Slot (0..*)
- Encounter -> Appointment (0..*)

**Medication Lifecycle:**
- MedicationRequest (order)
- MedicationDispense -> MedicationRequest (authorizingPrescription)
- MedicationAdministration -> MedicationRequest (request)

**Care Planning Chain:**
- CarePlan -> Goal, CareTeam, Condition (addresses)
- CarePlan.activity.reference -> ServiceRequest, MedicationRequest, Task, Appointment, etc.
- ServiceRequest <- Encounter.basedOn, Procedure.basedOn

**Supply Chain:**
- SupplyRequest (order)
- SupplyDelivery -> SupplyRequest (basedOn)

**Financial Chain:**
- Coverage -> Patient (beneficiary), Organization (payor)
- Claim -> Patient, Coverage, Encounter, Condition, Procedure, Location

**Provenance Pattern:**
- Provenance.target -> Any (tracks changes to any resource)
- Many resources have eventHistory/relevantHistory -> Provenance
