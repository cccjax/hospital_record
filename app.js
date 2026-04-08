const state = {
  activeModule: "patient",
  selectedPatientNo: "",
  selectedAdmissionId: "",
  patientDetailNo: "",
  patientDetailAdmissionId: "",
  patientDetailDailyId: "",
  patientDetailAssessmentId: "",
  patientDetailImagingPreviewId: "",
  patientInHospitalOnly: false,
  mineSubPage: "",
  templateView: "disease",
  templateSelectedDiseaseId: "",
  templateSelectedVersionId: "",
  templateExpandedDiseaseId: "",
  templateDiseaseSearchQuery: "",
  templateSimSelections: {},
  admissionAssessments: {},
  admissionImaging: {},
  admissionImagingPickerOpen: false,
  fieldsSortMode: false,
  schemas: {
    patient: [
      { key: "admissionNo", label: "住院号", type: "text", required: true, locked: true, showInList: false },
      { key: "name", label: "姓名", type: "text", required: true, showInList: true },
      { key: "gender", label: "性别", type: "select", options: ["男", "女"], required: true, showInList: true },
      { key: "age", label: "年龄", type: "number", required: true, showInList: true },
      { key: "phone", label: "联系电话", type: "text", required: false, showInList: false }
    ],
    admission: [
      { key: "admitDate", label: "入院日期", type: "date", required: true, locked: true, showInList: true },
      { key: "department", label: "科室", type: "text", required: true, showInList: true },
      { key: "diagnosis", label: "初步诊断", type: "text", required: true, showInList: true },
      { key: "attendingDoctor", label: "主治医生", type: "text", required: true, showInList: false },
      { key: "status", label: "状态", type: "select", options: ["在院", "出院"], required: true, showInList: true }
    ],
    daily: [
      { key: "recordDate", label: "记录日期", type: "date", required: true, showInList: true },
      { key: "temperature", label: "体温(℃)", type: "number", required: false, showInList: true },
      { key: "bloodPressure", label: "血压", type: "text", required: false, showInList: true },
      { key: "notes", label: "病情记录", type: "textarea", required: false, showInList: false }
    ],
    templateDisease: [
      { key: "diseaseCode", label: "病种编码", type: "text", required: false, showInList: true },
      { key: "versionCount", label: "版本数", type: "number", required: false, showInList: true, locked: true, computed: true },
      { key: "itemCount", label: "测评项总数", type: "number", required: false, showInList: true, locked: true, computed: true },
      { key: "description", label: "说明", type: "textarea", required: false, showInList: true }
    ],
    templateVersion: [
      { key: "year", label: "年度", type: "text", required: false, showInList: true },
      { key: "itemCount", label: "测评项", type: "number", required: false, showInList: true, locked: true, computed: true },
      { key: "optionCount", label: "选项数", type: "number", required: false, showInList: true, locked: true, computed: true },
      { key: "gradeCount", label: "分级区间", type: "number", required: false, showInList: true, locked: true, computed: true },
      { key: "description", label: "说明", type: "textarea", required: false, showInList: true }
    ]
  },
  patients: [
    { admissionNo: "ZY2026001", name: "张明", gender: "男", age: 42, phone: "13800001111" },
    { admissionNo: "ZY2026002", name: "李萍", gender: "女", age: 35, phone: "13800002222" }
  ],
  admissions: [
    {
      _id: uid("adm"),
      admissionNo: "ZY2026001",
      admitDate: "2026-04-05",
      department: "心内科",
      diagnosis: "冠心病",
      attendingDoctor: "李医生",
      status: "在院"
    },
    {
      _id: uid("adm"),
      admissionNo: "ZY2026002",
      admitDate: "2026-04-04",
      department: "普外科",
      diagnosis: "胆囊炎",
      attendingDoctor: "王医生",
      status: "在院"
    }
  ],
  dailyRecords: [],
  templates: []
};

const STORAGE_DATA_KEY = "hospital_record_prototype_data_v1";
const STORAGE_SECURITY_KEY = "hospital_record_prototype_security_v1";
const securityState = {
  passwordEnabled: false,
  passwordValue: ""
};

state.dailyRecords = [
  {
    _id: uid("daily"),
    admissionId: state.admissions[0]._id,
    recordDate: "2026-04-06",
    temperature: "37.1",
    bloodPressure: "128/83",
    notes: "生命体征平稳，睡眠可。"
  },
  {
    _id: uid("daily"),
    admissionId: state.admissions[0]._id,
    recordDate: "2026-04-07",
    temperature: "36.9",
    bloodPressure: "124/80",
    notes: "早餐后活动良好，无胸闷。"
  }
];

state.templates = [
  {
    id: uid("tpld"),
    diseaseName: "慢阻肺急性加重",
    diseaseCode: "COPD-AE",
    description: "用于评估住院慢阻肺病人急性加重风险等级。",
    versions: [
      {
        id: uid("tplv"),
        versionName: "2026版",
        year: "2026",
        description: "按2026年院内护理规范执行。",
        items: [
          {
            id: uid("tpli"),
            name: "呼吸困难程度",
            options: [
              { id: uid("tplo"), label: "轻度", score: 1 },
              { id: uid("tplo"), label: "中度", score: 3 },
              { id: uid("tplo"), label: "重度", score: 5 }
            ]
          },
          {
            id: uid("tpli"),
            name: "氧饱和度",
            options: [
              { id: uid("tplo"), label: ">=95%", score: 1 },
              { id: uid("tplo"), label: "90%-94%", score: 3 },
              { id: uid("tplo"), label: "<90%", score: 5 }
            ]
          },
          {
            id: uid("tpli"),
            name: "咳痰性状变化",
            options: [
              { id: uid("tplo"), label: "无明显变化", score: 1 },
              { id: uid("tplo"), label: "中等变化", score: 3 },
              { id: uid("tplo"), label: "明显恶化", score: 5 }
            ]
          }
        ],
        gradeRules: [
          { id: uid("tplg"), min: 0, max: 39, level: "低风险", note: "常规观察" },
          { id: uid("tplg"), min: 40, max: 69, level: "中风险", note: "加强巡查" },
          { id: uid("tplg"), min: 70, max: 100, level: "高风险", note: "重点监护" }
        ]
      },
      {
        id: uid("tplv"),
        versionName: "2024版",
        year: "2024",
        description: "历史版本，供追溯对照。",
        items: [],
        gradeRules: []
      }
    ]
  }
];

state.templateSelectedDiseaseId = state.templates[0]?.id || "";
state.templateSelectedVersionId = state.templates[0]?.versions?.[0]?.id || "";

hydrateFromStorage();
repairLegacyDataArtifacts();
enforceCoreFieldRules();
normalizeSelectionState();

const modalState = { onSubmit: null };
let assessmentDraft = null;
let assessmentDraftMode = "create";
let assessmentDraftSourceId = "";
let toastTimer = null;
let sessionUnlocked = !isPasswordEnabled();
const swipeState = { active: false, startX: 0, startY: 0 };
const fieldSortState = {
  active: false,
  pointerId: null,
  moduleKey: "",
  dragKey: "",
  dragCardEl: null,
  overKey: "",
  previewKey: "",
  moved: false,
  startX: 0,
  startY: 0,
  lastX: 0,
  lastY: 0,
  autoScrollSpeed: 0,
  autoScrollRaf: 0
};

const moduleMeta = {
  patient: {
    title: "首页",
    subtitle: "病人信息总览与住院过程管理",
    fab: "新增病人"
  },
  template: {
    title: "测评模板",
    subtitle: "病种版本、测评项与分级规则",
    fab: ""
  },
  mine: {
    title: "我的",
    subtitle: "安全设置、数据迁移与字段配置",
    fab: ""
  },
  admission: {
    title: "住院信息",
    subtitle: "入院记录与日常记录联动管理",
    fab: "新增入院"
  },
  fields: {
    title: "字段配置",
    subtitle: "配置字段并实时同步到业务模块",
    fab: "新增字段"
  }
};

const el = {
  pageTitle: document.getElementById("page-title"),
  pageSubtitle: document.getElementById("page-subtitle"),
  pages: {
    patient: document.getElementById("patient-page"),
    admission: document.getElementById("admission-page"),
    template: document.getElementById("template-page"),
    mine: document.getElementById("mine-page")
  },
  tabNav: document.getElementById("tab-nav"),
  pageHost: document.getElementById("page-host"),
  headerBackBtn: document.getElementById("header-back-btn"),

  patientListView: document.getElementById("patient-list-view"),
  patientDetailView: document.getElementById("patient-detail-view"),
  patientDetailListPane: document.getElementById("patient-detail-list-pane"),
  patientAdmissionDetailPane: document.getElementById("patient-admission-detail-pane"),
  patientDetailName: document.getElementById("patient-detail-name"),
  patientDetailSubtitle: document.getElementById("patient-detail-subtitle"),
  patientDetailStats: document.getElementById("patient-detail-stats"),
  patientDetailBasic: document.getElementById("patient-detail-basic"),
  patientDetailAdmissions: document.getElementById("patient-detail-admissions"),
  patientAddAdmissionBtn: document.getElementById("patient-add-admission-btn"),
  patientAddDailyBtn: document.getElementById("patient-add-daily-btn"),
  patientAdmissionOverviewPane: document.getElementById("patient-admission-overview-pane"),
  patientDailyDetailPane: document.getElementById("patient-daily-detail-pane"),
  patientAssessmentDetailPane: document.getElementById("patient-assessment-detail-pane"),
  patientAdmissionDetailCard: document.getElementById("patient-admission-detail-card"),
  patientAdmissionDaily: document.getElementById("patient-admission-daily"),
  patientDailyDetailCard: document.getElementById("patient-daily-detail-card"),
  patientAssessmentDetailCard: document.getElementById("patient-assessment-detail-card"),
  admissionAssessmentBtn: document.getElementById("admission-assessment-btn"),
  admissionTemplateSummary: document.getElementById("admission-template-summary"),
  admissionImagingSourceRow: document.getElementById("admission-imaging-source-row"),
  admissionImagingCameraInput: document.getElementById("admission-imaging-camera-input"),
  admissionImagingAlbumInput: document.getElementById("admission-imaging-album-input"),
  admissionImagingList: document.getElementById("admission-imaging-list"),

  patientStats: document.getElementById("patient-stats"),
  patientSearch: document.getElementById("patient-search"),
  patientList: document.getElementById("patient-list"),
  addPatientBtn: document.getElementById("add-patient-btn"),

  admissionStats: document.getElementById("admission-stats"),
  admissionPatientSelect: document.getElementById("admission-patient-select"),
  admissionList: document.getElementById("admission-list"),
  dailyList: document.getElementById("daily-list"),
  addAdmissionBtn: document.getElementById("add-admission-btn"),
  addDailyBtn: document.getElementById("add-daily-btn"),

  templateStats: document.getElementById("template-stats"),
  templateDiseasePane: document.getElementById("template-disease-pane"),
  templateVersionPane: document.getElementById("template-version-pane"),
  templateConfigPane: document.getElementById("template-config-pane"),
  addTemplateDiseaseBtn: document.getElementById("add-template-disease-btn"),
  addTemplateVersionBtn: document.getElementById("add-template-version-btn"),
  addTemplateItemBtn: document.getElementById("add-template-item-btn"),
  addTemplateGradeBtn: document.getElementById("add-template-grade-btn"),
  templateDiseaseSearch: document.getElementById("template-disease-search"),
  templateDiseaseList: document.getElementById("template-disease-list"),
  templateVersionTitle: document.getElementById("template-version-title"),
  templateVersionList: document.getElementById("template-version-list"),
  templateItemTitle: document.getElementById("template-item-title"),
  templateItemList: document.getElementById("template-item-list"),
  templateGradeList: document.getElementById("template-grade-list"),
  // template simulator removed

  fieldStats: document.getElementById("field-stats"),
  schemaModuleSelect: document.getElementById("schema-module-select"),
  fieldSortModeBtn: document.getElementById("field-sort-mode-btn"),
  fieldList: document.getElementById("field-list"),
  addFieldBtn: document.getElementById("add-field-btn"),

  minePage: document.getElementById("mine-page"),
  mineHomePane: document.getElementById("mine-home-pane"),
  mineMigrationPane: document.getElementById("mine-migration-pane"),
  mineSecurityPane: document.getElementById("mine-security-pane"),
  mineFieldsPane: document.getElementById("mine-fields-pane"),
  mineSecurityMenuTag: document.getElementById("mine-security-menu-tag"),

  exportDataBtn: document.getElementById("export-data-btn"),
  importDataBtn: document.getElementById("import-data-btn"),
  importFileInput: document.getElementById("import-file-input"),
  mineSecurityStatus: document.getElementById("mine-security-status"),
  mineSecurityHint: document.getElementById("mine-security-hint"),
  mineSecurityActions: document.getElementById("mine-security-actions"),

  appLockOverlay: document.getElementById("app-lock-overlay"),
  appLockInput: document.getElementById("app-lock-input"),
  appUnlockBtn: document.getElementById("app-unlock-btn"),
  appLockError: document.getElementById("app-lock-error"),

  modalOverlay: document.getElementById("modal-overlay"),
  modalShell: document.getElementById("modal-shell"),
  modalTitle: document.getElementById("modal-title"),
  modalSubtitle: document.getElementById("modal-subtitle"),
  modalForm: document.getElementById("modal-form"),
  modalClose: document.getElementById("modal-close"),
  modalCancel: document.getElementById("modal-cancel"),
  modalSubmit: document.getElementById("modal-submit"),
  imagingPreviewOverlay: document.getElementById("imaging-preview-overlay"),
  imagingPreviewClose: document.getElementById("imaging-preview-close"),
  imagingPreviewImage: document.getElementById("imaging-preview-image"),
  imagingPreviewCaption: document.getElementById("imaging-preview-caption"),

  toast: document.getElementById("toast")
};

bindEvents();
renderAll();
persistDataState();
persistSecurityState();
applyLockState();

function bindEvents() {
  el.tabNav.addEventListener("click", (event) => {
    const tab = event.target.closest(".tab-item");
    if (!tab) return;

    if (tab.dataset.module === "patient" && state.activeModule === "patient" && state.patientDetailNo) {
      closePatientDetail(true);
      return;
    }
    if (tab.dataset.module === "mine" && state.activeModule === "mine" && state.mineSubPage) {
      closeMineSubPage(true);
      return;
    }
    if (tab.dataset.module === "template" && state.activeModule === "template" && state.templateView !== "disease") {
      closeTemplateDetail(true);
      return;
    }

    switchModule(tab.dataset.module, true);
  });

  el.patientSearch.addEventListener("input", renderPatientSection);
  el.patientStats.addEventListener("click", handlePatientStatsActions);
  el.addPatientBtn.addEventListener("click", openAddPatientModal);
  el.patientAddAdmissionBtn.addEventListener("click", openAddAdmissionFromPatientDetail);
  el.patientAddDailyBtn.addEventListener("click", openAddDailyFromPatientDetail);
  if (el.admissionImagingCameraInput) {
    el.admissionImagingCameraInput.addEventListener("change", () => {
      handleAdmissionImagingFileInput(el.admissionImagingCameraInput);
    });
  }
  if (el.admissionImagingAlbumInput) {
    el.admissionImagingAlbumInput.addEventListener("change", () => {
      handleAdmissionImagingFileInput(el.admissionImagingAlbumInput);
    });
  }
  el.headerBackBtn.addEventListener("click", handleHeaderBack);

  el.admissionPatientSelect.addEventListener("change", () => {
    state.selectedPatientNo = el.admissionPatientSelect.value;
    state.selectedAdmissionId = "";
    renderAdmissionSection();
  });
  el.addAdmissionBtn.addEventListener("click", openAddAdmissionModal);
  el.addDailyBtn.addEventListener("click", openAddDailyModal);

  el.addTemplateDiseaseBtn.addEventListener("click", openAddTemplateDiseaseModal);
  el.addTemplateVersionBtn.addEventListener("click", openAddTemplateVersionModal);
  el.addTemplateItemBtn.addEventListener("click", openAddTemplateItemModal);
  el.addTemplateGradeBtn.addEventListener("click", openAddTemplateGradeModal);
  if (el.templateDiseaseSearch) {
    el.templateDiseaseSearch.addEventListener("input", () => {
      state.templateDiseaseSearchQuery = String(el.templateDiseaseSearch.value || "").trim();
      if (state.activeModule === "template" && state.templateView === "disease") {
        renderTemplateSection();
      }
    });
  }

  el.schemaModuleSelect.addEventListener("change", renderFieldSection);
  el.addFieldBtn.addEventListener("click", openAddFieldModal);
  el.fieldSortModeBtn.addEventListener("click", toggleFieldSortMode);
  el.exportDataBtn.addEventListener("click", exportDataFile);
  el.importDataBtn.addEventListener("click", () => {
    el.importFileInput.value = "";
    el.importFileInput.click();
  });
  el.importFileInput.addEventListener("change", handleImportDataFile);
  el.mineSecurityActions.addEventListener("click", handleMineActions);
  el.minePage.addEventListener("click", handleMineMenuNavigation);
  el.appUnlockBtn.addEventListener("click", tryUnlockApp);
  el.appLockInput.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      tryUnlockApp();
    }
  });

  el.patientList.addEventListener("click", handlePatientActions);
  el.patientDetailBasic.addEventListener("click", handlePatientActions);
  el.patientDetailAdmissions.addEventListener("click", handlePatientActions);
  el.patientAdmissionDetailCard.addEventListener("click", handlePatientActions);
  el.patientAdmissionDaily.addEventListener("click", handlePatientActions);
  el.patientDailyDetailCard.addEventListener("click", handlePatientActions);
  if (el.admissionImagingSourceRow) {
    el.admissionImagingSourceRow.addEventListener("click", handlePatientActions);
  }
  if (el.admissionImagingList) {
    el.admissionImagingList.addEventListener("click", handlePatientActions);
  }
  if (el.patientAssessmentDetailCard) {
    el.patientAssessmentDetailCard.addEventListener("click", handlePatientActions);
  }
  if (el.admissionTemplateSummary) {
    el.admissionTemplateSummary.addEventListener("click", handlePatientActions);
  }
  el.admissionList.addEventListener("click", handleAdmissionActions);
  el.dailyList.addEventListener("click", handleDailyActions);
  el.templateDiseaseList.addEventListener("click", handleTemplateActions);
  el.templateVersionList.addEventListener("click", handleTemplateActions);
  el.templateItemList.addEventListener("click", handleTemplateActions);
  el.templateGradeList.addEventListener("click", handleTemplateActions);
  if (el.admissionAssessmentBtn) {
    el.admissionAssessmentBtn.addEventListener("click", openAdmissionAssessmentModal);
  }
  el.fieldList.addEventListener("click", handleFieldActions);
  el.fieldList.addEventListener("pointerdown", handleFieldSortPointerDown);
  window.addEventListener("pointermove", handleFieldSortPointerMove);
  window.addEventListener("pointerup", handleFieldSortPointerUp);
  window.addEventListener("pointercancel", handleFieldSortPointerCancel);

  el.modalClose.addEventListener("click", closeModal);
  el.modalCancel.addEventListener("click", closeModal);
  el.modalSubmit.addEventListener("click", submitModal);
  el.modalForm.addEventListener("click", handleModalFormActions);
  el.modalForm.addEventListener("input", handleModalFormInput);
  el.modalForm.addEventListener("change", handleModalFormChange);
  el.modalOverlay.addEventListener("click", (event) => {
    if (event.target === el.modalOverlay) closeModal();
  });
  if (el.imagingPreviewClose) {
    el.imagingPreviewClose.addEventListener("click", closeAdmissionImagingPreview);
  }
  if (el.imagingPreviewOverlay) {
    el.imagingPreviewOverlay.addEventListener("click", (event) => {
      if (event.target === el.imagingPreviewOverlay) {
        closeAdmissionImagingPreview();
      }
    });
  }
  window.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      closeAdmissionImagingPreview();
    }
  });

  el.pageHost.addEventListener("touchstart", handleEdgeSwipeStart, { passive: true });
  el.pageHost.addEventListener("touchmove", handleEdgeSwipeMove, { passive: true });
  el.pageHost.addEventListener("touchend", handleEdgeSwipeEnd, { passive: true });
  el.pageHost.addEventListener("touchcancel", resetEdgeSwipe, { passive: true });
}

function renderAll() {
  switchModule(state.activeModule, true);
  renderPatientSection();
  renderAdmissionSection();
  renderTemplateSection();
  renderFieldSection();
  renderMineSection();
}

function switchModule(moduleKey, silent = false) {
  const prevModule = state.activeModule;
  if (moduleKey !== "patient") {
    closeAdmissionImagingPreview();
  }
  if (!el.pages[moduleKey]) {
    moduleKey = "patient";
  }

  if (moduleKey === "mine" && prevModule !== "mine") {
    state.mineSubPage = "";
  }
  if (moduleKey === "template" && prevModule !== "template") {
    state.templateView = "disease";
  }

  if ((moduleKey !== "mine" || state.mineSubPage !== "fields") && state.fieldsSortMode) {
    state.fieldsSortMode = false;
    resetFieldSortState();
    clearFieldSortVisuals();
  }

  state.activeModule = moduleKey;

  Object.entries(el.pages).forEach(([key, node]) => {
    node.classList.toggle("active", key === moduleKey);
  });

  document.querySelectorAll(".tab-item").forEach((tab) => {
    tab.classList.toggle("active", tab.dataset.module === moduleKey);
  });

  if (moduleKey === "mine") {
    renderMineSection();
  }
  if (moduleKey === "template") {
    // Ensure template pane visibility always matches templateView after tab switch.
    renderTemplateSection();
  }

  refreshPageHeader();
  refreshFabVisibility();

}

function refreshPageHeader() {
  let title = "";
  let subtitle = "";

  if (state.activeModule === "patient" && state.patientDetailNo) {
    const admission = state.patientDetailAdmissionId
      ? state.admissions.find((item) =>
        item._id === state.patientDetailAdmissionId && item.admissionNo === state.patientDetailNo)
      : null;
    const daily = state.patientDetailDailyId
      ? state.dailyRecords.find((item) =>
        item._id === state.patientDetailDailyId && item.admissionId === state.patientDetailAdmissionId)
      : null;
    if (admission && daily) {
      title = "日常详情";
      subtitle = `${daily.recordDate || "未填写日期"} · 完整记录`;
    } else if (admission) {
      title = "入院详情";
      subtitle = `${admission.admitDate || "未填写日期"} · 入院过程与日常记录`;
    } else {
      title = "病人明细";
      subtitle = "基础信息与住院过程记录";
    }
  } else if (state.activeModule === "template") {
    const disease = getSelectedTemplateDisease();
    const version = getSelectedTemplateVersion();
    if (state.templateView === "config" && disease && version) {
      title = version.versionName || "\u6d4b\u8bc4\u7248\u672c";
      subtitle = `${disease.diseaseName} \u00b7 \u6d4b\u8bc4\u9879\u914d\u7f6e`;
    } else {
      title = "\u6d4b\u8bc4\u6a21\u677f";
      subtitle = "\u75c5\u79cd\u5217\u8868";
    }
  } else if (state.activeModule === "mine" && state.mineSubPage) {
    if (state.mineSubPage === "migration") {
      title = "数据迁移";
      subtitle = "导入导出本机数据，支持跨设备离线转移";
    } else if (state.mineSubPage === "security") {
      title = "密码保护";
      subtitle = "设置访问密码，应用启动前进行校验";
    } else if (state.mineSubPage === "fields") {
      title = "字段配置";
      subtitle = "配置字段并实时同步到业务模块";
    }
  } else {
    const meta = moduleMeta[state.activeModule];
    title = meta.title;
    subtitle = meta.subtitle;
  }

  const hideHomeSubtitle = state.activeModule === "patient" && !state.patientDetailNo;
  el.pageTitle.textContent = title;
  el.pageSubtitle.textContent = hideHomeSubtitle ? "" : subtitle;
  el.pageSubtitle.classList.toggle("hidden", hideHomeSubtitle || !subtitle);
}

function refreshFabVisibility() {
  const inRootPatient = state.activeModule === "patient" && !state.patientDetailNo;
  const inRootTemplate = state.activeModule === "template" && state.templateView === "disease";
  const inRootMine = state.activeModule === "mine" && !state.mineSubPage;
  const showHeaderBack = !(inRootPatient || inRootTemplate || inRootMine);
  el.headerBackBtn.classList.toggle("hidden", !showHeaderBack);
}

function handleHeaderBack() {
  if (state.activeModule === "template" && state.templateView !== "disease") {
    closeTemplateDetail();
    return;
  }
  if (state.activeModule === "mine" && state.mineSubPage) {
    closeMineSubPage();
    return;
  }
  if (state.activeModule !== "patient") {
    switchModule("patient", true);
    renderPatientSection();
    return;
  }
  closePatientDetail();
}

function closePatientDetail(silent = false) {
  if (state.patientDetailAssessmentId) {
    state.patientDetailAssessmentId = "";
    state.admissionImagingPickerOpen = false;
    syncAdmissionImagingSourceRow();
    renderPatientSection();
    // no toast on back navigation
    return;
  }
  if (state.patientDetailDailyId) {
    state.patientDetailDailyId = "";
    state.admissionImagingPickerOpen = false;
    syncAdmissionImagingSourceRow();
    renderPatientSection();
    // no toast on back navigation
    return;
  }
  if (state.patientDetailAdmissionId) {
    state.patientDetailAdmissionId = "";
    state.patientDetailDailyId = "";
    state.patientDetailAssessmentId = "";
    state.patientDetailImagingPreviewId = "";
    state.admissionImagingPickerOpen = false;
    syncAdmissionImagingSourceRow();
    renderPatientSection();
    // no toast on back navigation
    return;
  }
  if (!state.patientDetailNo) return;
  state.patientDetailNo = "";
  state.patientDetailAdmissionId = "";
  state.patientDetailDailyId = "";
  state.patientDetailAssessmentId = "";
  state.patientDetailImagingPreviewId = "";
  state.admissionImagingPickerOpen = false;
  syncAdmissionImagingSourceRow();
  renderPatientSection();
  // no toast on back navigation
}

function closeTemplateDetail(silent = false) {
  if (state.templateView !== "disease") {
    state.templateView = "disease";
    state.templateSelectedVersionId = "";
    state.templateExpandedDiseaseId = state.templateSelectedDiseaseId || state.templateExpandedDiseaseId;
    renderTemplateSection();
    // no toast on back navigation
    return;
  }
}

function openTemplateVersionView(diseaseId, silent = false) {
  if (!diseaseId) return;
  state.templateView = "disease";
  state.templateSelectedDiseaseId = diseaseId;
  state.templateSelectedVersionId = "";
  state.templateExpandedDiseaseId = state.templateExpandedDiseaseId === diseaseId ? "" : diseaseId;
  renderTemplateSection();
}

function openTemplateConfigView(versionId, silent = false) {
  const disease = getSelectedTemplateDisease();
  if (!disease) return;
  const versionExists = (disease.versions || []).some((item) => item.id === versionId);
  if (!versionExists) return;
  state.templateSelectedVersionId = versionId;
  normalizeTemplateSelection();
  state.templateView = "config";
  state.templateExpandedDiseaseId = disease.id;
  renderTemplateSection();
}

function renderPatientSection() {
  const keyword = el.patientSearch.value.trim().toLowerCase();
  const inHospitalSet = getInHospitalPatientNoSet();
  const rows = state.patients.filter((item) => {
    if (state.patientInHospitalOnly && !inHospitalSet.has(item.admissionNo)) return false;
    if (!keyword) return true;
    return String(item.admissionNo || "").toLowerCase().includes(keyword)
      || String(item.name || "").toLowerCase().includes(keyword);
  });

  el.patientStats.innerHTML = [
    statItem("病人总数", state.patients.length),
    renderInHospitalFilterStat(inHospitalSet.size, state.patientInHospitalOnly)
  ].join("");

  const emptyText = state.patientInHospitalOnly
    ? "暂无符合“在院病人”筛选条件的数据"
    : "暂无病人数据";
  el.patientList.innerHTML = rows.length
    ? rows.map(renderPatientCard).join("")
    : `<div class="empty">${emptyText}</div>`;

  const inDetail = !!state.patientDetailNo;
  el.patientListView.classList.toggle("hidden", inDetail);
  el.patientDetailView.classList.toggle("hidden", !inDetail);

  if (inDetail) {
    renderPatientDetailView();
  }

  refreshPageHeader();
  refreshFabVisibility();
}

function handlePatientStatsActions(event) {
  const trigger = event.target.closest("[data-action='toggle-in-hospital-filter']");
  if (!trigger) return;

  state.patientInHospitalOnly = !state.patientInHospitalOnly;
  renderPatientSection();
  showToast(state.patientInHospitalOnly ? "已筛选在院病人" : "已取消在院筛选");
}

function canSwipeBackFromDetail() {
  const inRootPatient = state.activeModule === "patient" && !state.patientDetailNo;
  const inRootTemplate = state.activeModule === "template" && state.templateView === "disease";
  const inRootMine = state.activeModule === "mine" && !state.mineSubPage;
  return !(inRootPatient || inRootTemplate || inRootMine);
}

function handleEdgeSwipeStart(event) {
  if (!canSwipeBackFromDetail()) return;
  if (!event.touches || event.touches.length !== 1) return;

  const touch = event.touches[0];
  if (touch.clientX > 24) return;

  swipeState.active = true;
  swipeState.startX = touch.clientX;
  swipeState.startY = touch.clientY;
}

function handleEdgeSwipeMove(event) {
  if (!swipeState.active) return;
  if (!event.touches || event.touches.length !== 1) return;

  const touch = event.touches[0];
  const deltaX = touch.clientX - swipeState.startX;
  const deltaY = Math.abs(touch.clientY - swipeState.startY);

  if (deltaX < -8 || deltaY > 90) {
    resetEdgeSwipe();
  }
}

function handleEdgeSwipeEnd(event) {
  if (!swipeState.active) return;
  const touch = event.changedTouches?.[0];
  if (!touch) {
    resetEdgeSwipe();
    return;
  }

  const deltaX = touch.clientX - swipeState.startX;
  const deltaY = Math.abs(touch.clientY - swipeState.startY);
  resetEdgeSwipe();

  if (deltaX >= 70 && deltaY <= 90) {
    handleHeaderBack();
  }
}

function resetEdgeSwipe() {
  swipeState.active = false;
  swipeState.startX = 0;
  swipeState.startY = 0;
}

function renderPatientCard(patient) {
  const visibleFields = state.schemas.patient
    .filter((field) => field.key !== "admissionNo" && isFieldVisibleInList("patient", field));

  const fields = visibleFields.length
    ? visibleFields.map((field) => fieldItem(field.label, formatFieldValue(field, patient[field.key]), field.type === "textarea")).join("")
    : fieldItem("提示", "当前未配置列表显示字段，请在字段配置中开启");

  return `
    <article class="entity-card patient-card daily-ref-card" data-patient-id="${esc(patient.admissionNo)}">
      <div class="entity-head patient-card-head">
        <div class="entity-title patient-name">${esc(patient.name || "未命名病人")}</div>
        <div class="patient-head-right">
          <span class="entity-tag patient-admission-no">住院号 ${esc(patient.admissionNo)}</span>
          <div class="patient-row-actions">
            <button class="mini-btn edit" data-action="edit-patient" data-id="${esc(patient.admissionNo)}">编辑</button>
            <button class="mini-btn delete" data-action="delete-patient" data-id="${esc(patient.admissionNo)}">删除</button>
          </div>
        </div>
      </div>
      <div class="field-grid overview-field-grid daily-overview-grid">${fields}</div>
      <span class="patient-chevron" aria-hidden="true">›</span>
    </article>
  `;
}

function renderPatientDetailView() {
  const patient = state.patients.find((item) => item.admissionNo === state.patientDetailNo);
  if (!patient) {
    closeAdmissionImagingPreview();
    state.patientDetailNo = "";
    state.patientDetailAdmissionId = "";
    state.patientDetailDailyId = "";
    state.patientDetailAssessmentId = "";
    el.patientListView.classList.remove("hidden");
    el.patientDetailView.classList.add("hidden");
    refreshPageHeader();
    refreshFabVisibility();
    return;
  }

  const admissions = state.admissions
    .filter((item) => item.admissionNo === patient.admissionNo)
    .sort((a, b) => String(b.admitDate || "").localeCompare(String(a.admitDate || "")));
  const admissionIdSet = new Set(admissions.map((item) => item._id));
  if (state.patientDetailAdmissionId && !admissionIdSet.has(state.patientDetailAdmissionId)) {
    state.patientDetailAdmissionId = "";
    state.patientDetailDailyId = "";
    state.patientDetailAssessmentId = "";
  }

  const totalDailyCount = state.dailyRecords.filter((item) => admissionIdSet.has(item.admissionId)).length;
  const inAdmissionDetail = !!state.patientDetailAdmissionId;

  el.patientDetailListPane.classList.toggle("hidden", inAdmissionDetail);
  el.patientAdmissionDetailPane.classList.toggle("hidden", !inAdmissionDetail);

  const patientFields = state.schemas.patient
    .map((field) => fieldItem(field.label, formatFieldValue(field, patient[field.key]), field.type === "textarea"))
    .join("");

  if (!inAdmissionDetail) {
    state.patientDetailDailyId = "";
    state.patientDetailAssessmentId = "";
    state.patientDetailImagingPreviewId = "";
    state.admissionImagingPickerOpen = false;
    closeAdmissionImagingPreview();
    syncAdmissionImagingSourceRow();
    el.patientDetailStats.classList.remove("stats-triple");
    el.patientDetailName.textContent = "病人概况";
    el.patientDetailSubtitle.textContent = "基础信息与住院过程记录";
    el.patientDetailStats.innerHTML = [
      statItem("入院记录", admissions.length),
      statItem("日常记录", totalDailyCount)
    ].join("");

    el.patientDetailBasic.innerHTML = `
      <article class="entity-card">
        <div class="entity-head">
          <div class="entity-title">基础档案</div>
          <div class="patient-inline-actions">
            <button class="mini-btn edit" data-action="edit-patient" data-id="${esc(patient.admissionNo)}">编辑基础信息</button>
          </div>
        </div>
        <div class="field-grid">${patientFields}</div>
      </article>
    `;

    el.patientDetailAdmissions.innerHTML = admissions.length
      ? admissions.map(renderPatientAdmissionCard).join("")
      : `<div class="empty">暂无入院记录</div>`;
    return;
  }

  const admission = admissions.find((item) => item._id === state.patientDetailAdmissionId);
  if (!admission) {
    state.patientDetailAdmissionId = "";
    state.patientDetailAssessmentId = "";
    state.patientDetailImagingPreviewId = "";
    state.admissionImagingPickerOpen = false;
    closeAdmissionImagingPreview();
    syncAdmissionImagingSourceRow();
    renderPatientDetailView();
    return;
  }

  const dailyRows = state.dailyRecords
    .filter((item) => item.admissionId === admission._id)
    .sort((a, b) => String(b.recordDate || "").localeCompare(String(a.recordDate || "")));
  if (state.patientDetailDailyId && !dailyRows.some((item) => item._id === state.patientDetailDailyId)) {
    state.patientDetailDailyId = "";
  }
  const assessmentStore = normalizeAdmissionAssessmentStore(admission._id);
  const assessmentRecords = assessmentStore.records || [];
  if (state.patientDetailAssessmentId && !assessmentRecords.some((item) => item.id === state.patientDetailAssessmentId)) {
    state.patientDetailAssessmentId = "";
  }
  const inDailyDetail = !!state.patientDetailDailyId;
  const inAssessmentDetail = !!state.patientDetailAssessmentId;

  el.patientAdmissionOverviewPane.classList.toggle("hidden", inDailyDetail || inAssessmentDetail);
  el.patientDailyDetailPane.classList.toggle("hidden", !inDailyDetail);
  el.patientAssessmentDetailPane.classList.toggle("hidden", !inAssessmentDetail);

  if (!inDailyDetail && !inAssessmentDetail) {
    const imagingCount = normalizeImageItems(state.admissionImaging?.[admission._id] || []).length;
    const assessmentCount = assessmentRecords.length;
    el.patientDetailName.innerHTML = `
      <span>${esc(patient.name || "未命名病人")}</span>
      <span class="entity-tag patient-detail-admission-tag">住院号 ${esc(patient.admissionNo)}</span>
    `;
    el.patientDetailSubtitle.textContent = `${admission.admitDate || "未填写日期"} · ${admission.diagnosis || "未填写诊断"}`;
    el.patientDetailStats.classList.add("stats-triple");
    el.patientDetailStats.innerHTML = [
      statItem("日常记录", dailyRows.length),
      statItem("影像资料", imagingCount),
      statItem("住院测评", assessmentCount)
    ].join("");

    el.patientAdmissionDetailCard.innerHTML = renderAdmissionDetailCard(admission);
    el.patientAdmissionDaily.innerHTML = dailyRows.length
      ? dailyRows.map(renderDailyDetailCard).join("")
      : `<div class="empty">当前入院记录暂无日常记录</div>`;
    renderAdmissionAssessmentSection(admission);
    renderAdmissionImagingSection(admission);
    return;
  }

  state.admissionImagingPickerOpen = false;
  closeAdmissionImagingPreview();
  syncAdmissionImagingSourceRow();

  if (inDailyDetail) {
    const daily = dailyRows.find((item) => item._id === state.patientDetailDailyId);
    if (!daily) {
      state.patientDetailDailyId = "";
      renderPatientDetailView();
      return;
    }

    el.patientDetailStats.classList.remove("stats-triple");
    el.patientDetailName.textContent = `${patient.name}`;
    el.patientDetailSubtitle.textContent = `${daily.recordDate || "未填写日期"} · ${admission.admitDate || "未填写入院日期"}`;
    el.patientDetailStats.innerHTML = [
      statItem("住院号", patient.admissionNo),
      statItem("记录日期", daily.recordDate || "-")
    ].join("");
    el.patientDailyDetailCard.innerHTML = renderDailyRecordDetailCard(daily);
    return;
  }

  const record = assessmentRecords.find((item) => item.id === state.patientDetailAssessmentId);
  if (!record) {
    state.patientDetailAssessmentId = "";
    renderPatientDetailView();
    return;
  }

  const meta = getAssessmentRecordMeta(record);
  el.patientDetailStats.classList.remove("stats-triple");
  el.patientDetailName.textContent = `${patient.name} · 测评明细`;
  el.patientDetailSubtitle.textContent = `${meta.diseaseName} · ${meta.versionName}`;
  el.patientDetailStats.innerHTML = [
    statItem("住院号", patient.admissionNo),
    statItem("测评时间", formatDateTime(record.createdAt))
  ].join("");
  el.patientAssessmentDetailCard.innerHTML = renderAssessmentDetailView(record, admission);
}

function renderPatientAdmissionCard(admission) {
  const visibleFields = state.schemas.admission.filter((field) => isFieldVisibleInList("admission", field));
  const fields = visibleFields.length
    ? visibleFields.map((field) => fieldItem(field.label, formatFieldValue(field, admission[field.key]), field.type === "textarea")).join("")
    : fieldItem("提示", "当前未配置入院列表显示字段，请在字段配置中开启");
  const dailyCount = state.dailyRecords.filter((item) => item.admissionId === admission._id).length;

  return `
    <article class="entity-card patient-admission-card daily-ref-card" data-action="open-patient-admission-detail" data-id="${esc(admission._id)}">
      <div class="entity-head">
        <div class="entity-title">${esc(admission.admitDate || "未填写入院日期")}</div>
        <div class="patient-inline-actions">
          <span class="entity-tag">日常 ${dailyCount} 条</span>
          <button class="mini-btn edit" data-action="edit-admission-inline" data-id="${esc(admission._id)}">编辑</button>
          <button class="mini-btn delete" data-action="delete-admission-inline" data-id="${esc(admission._id)}">删除</button>
        </div>
      </div>
      <div class="field-grid overview-field-grid daily-overview-grid">${fields}</div>
      <span class="patient-chevron admission-chevron" aria-hidden="true">›</span>
    </article>
  `;
}

function renderAdmissionDetailCard(admission) {
  const fields = state.schemas.admission
    .map((field) => fieldItem(field.label, formatFieldValue(field, admission[field.key]), field.type === "textarea"))
    .join("");

  return `
    <article class="entity-card overview-static-card">
      <div class="entity-head">
        <div class="entity-title">${esc(admission.admitDate || "未填写入院日期")}</div>
        <div class="patient-inline-actions overview-card-actions">
          <button class="mini-btn edit overview-action-btn" data-action="edit-admission-detail" data-id="${esc(admission._id)}">编辑</button>
        </div>
      </div>
      <div class="field-grid overview-field-grid admission-detail-grid">${fields}</div>
    </article>
  `;
}

function renderDailyDetailCard(row) {
  const visibleFields = state.schemas.daily.filter((field) => isFieldVisibleInList("daily", field));
  const fields = visibleFields.length
    ? visibleFields.map((field) => fieldItem(field.label, formatFieldValue(field, row[field.key]), field.type === "textarea")).join("")
    : fieldItem("提示", "当前未配置日常列表显示字段，请在字段配置中开启");

  return `
    <article class="entity-card patient-daily-card overview-click-card" data-id="${esc(row._id)}">
      <div class="entity-head">
        <div class="entity-title">${esc(row.recordDate || "未填写日期")}</div>
        <div class="patient-inline-actions overview-card-actions">
          <button class="mini-btn edit overview-action-btn" data-action="edit-daily-inline" data-id="${esc(row._id)}">编辑</button>
          <button class="mini-btn delete overview-action-btn" data-action="delete-daily-inline" data-id="${esc(row._id)}">删除</button>
        </div>
      </div>
      <div class="field-grid overview-field-grid daily-overview-grid">${fields}</div>
      <span class="patient-chevron daily-chevron" aria-hidden="true">›</span>
    </article>
  `;
}

function renderDailyRecordDetailCard(row) {
  const fields = state.schemas.daily
    .map((field) => fieldItem(field.label, formatFieldValue(field, row[field.key]), field.type === "textarea"))
    .join("");

  return `
    <article class="entity-card overview-static-card">
      <div class="entity-head">
        <div class="entity-title">${esc(row.recordDate || "未填写日期")}</div>
        <div class="patient-inline-actions overview-card-actions">
          <button class="mini-btn edit overview-action-btn" data-action="edit-daily-inline" data-id="${esc(row._id)}">编辑</button>
          <button class="mini-btn delete overview-action-btn" data-action="delete-daily-inline" data-id="${esc(row._id)}">删除</button>
        </div>
      </div>
      <div class="field-grid overview-field-grid daily-overview-grid">${fields}</div>
    </article>
  `;
}

function handlePatientActions(event) {
  const btn = event.target.closest("button");
  if (btn) {
    const id = btn.dataset.id;
    const action = btn.dataset.action;

    if (action === "go-admission") {
      state.selectedPatientNo = id;
      state.patientDetailNo = "";
      state.patientDetailAdmissionId = "";
      state.patientDetailDailyId = "";
      state.patientDetailAssessmentId = "";
      switchModule("admission");
      renderAdmissionSection();
      return;
    }

    if (action === "edit-patient") {
      const patient = state.patients.find((item) => item.admissionNo === id);
      if (!patient) return;
      openPatientModal("编辑病人信息", patient, true);
      return;
    }

    if (action === "edit-admission-inline" || action === "edit-admission-detail") {
      editAdmissionById(id);
      return;
    }

    if (action === "delete-admission-inline" || action === "delete-admission-detail") {
      deleteAdmissionById(id);
      return;
    }

    if (action === "edit-daily-inline") {
      editDailyById(id);
      return;
    }

    if (action === "delete-daily-inline") {
      deleteDailyById(id);
      return;
    }

    if (action === "edit-assessment-record") {
      openEditAdmissionAssessmentModal(id);
      return;
    }

    if (action === "delete-assessment-record") {
      deleteAdmissionAssessmentRecord(id);
      return;
    }

    if (action === "admission-imaging-camera") {
      if (!el.admissionImagingCameraInput || !state.patientDetailAdmissionId) return;
      el.admissionImagingCameraInput.value = "";
      el.admissionImagingCameraInput.click();
      return;
    }

    if (action === "admission-imaging-album") {
      if (!el.admissionImagingAlbumInput || !state.patientDetailAdmissionId) return;
      el.admissionImagingAlbumInput.value = "";
      el.admissionImagingAlbumInput.click();
      return;
    }

    if (action === "select-admission-image") {
      if (!id) return;
      state.patientDetailImagingPreviewId = id;
      openAdmissionImagingPreview(id);
      renderAdmissionImagingThumbActiveState(id);
      return;
    }

    if (action === "remove-admission-image") {
      if (!id || !state.patientDetailAdmissionId) return;
      if (!confirm("确认删除该影像资料吗？")) return;
      const removed = removeAdmissionImagingItem(state.patientDetailAdmissionId, id);
      if (!removed) return;
      if (state.patientDetailImagingPreviewId === id) {
        state.patientDetailImagingPreviewId = "";
        closeAdmissionImagingPreview();
      }
      persistDataState();
      renderPatientSection();
      showToast("影像资料已删除");
      return;
    }

    if (action === "delete-patient") {
      if (!confirm(`确认删除住院号 ${id} 的病人信息吗？`)) return;

      const affectedAdmissionIds = state.admissions
        .filter((item) => item.admissionNo === id)
        .map((item) => item._id);

      state.patients = state.patients.filter((item) => item.admissionNo !== id);
      state.admissions = state.admissions.filter((item) => item.admissionNo !== id);
      state.dailyRecords = state.dailyRecords.filter((item) => !affectedAdmissionIds.includes(item.admissionId));
      if (state.admissionAssessments) {
        affectedAdmissionIds.forEach((admissionId) => {
          delete state.admissionAssessments[admissionId];
        });
      }
      if (state.admissionImaging) {
        affectedAdmissionIds.forEach((admissionId) => {
          delete state.admissionImaging[admissionId];
        });
      }

      if (state.selectedPatientNo === id) {
        state.selectedPatientNo = state.patients[0]?.admissionNo || "";
        state.selectedAdmissionId = "";
      }

      if (state.patientDetailNo === id) {
        state.patientDetailNo = "";
        state.patientDetailAdmissionId = "";
        state.patientDetailAssessmentId = "";
        state.patientDetailImagingPreviewId = "";
        state.admissionImagingPickerOpen = false;
        closeAdmissionImagingPreview();
        syncAdmissionImagingSourceRow();
      }

      persistDataState();
      renderAll();
      showToast("病人已删除");
    }
    return;
  }

  const admissionCard = event.target.closest(".patient-admission-card[data-id]");
  if (admissionCard) {
    state.patientDetailAdmissionId = admissionCard.dataset.id;
    state.patientDetailDailyId = "";
    state.patientDetailAssessmentId = "";
    state.patientDetailImagingPreviewId = "";
    state.admissionImagingPickerOpen = false;
    renderPatientSection();
    return;
  }

  const dailyCard = event.target.closest(".patient-daily-card[data-id]");
  if (dailyCard) {
    state.patientDetailDailyId = dailyCard.dataset.id;
    state.patientDetailAssessmentId = "";
    renderPatientSection();
    return;
  }

  const assessmentCard = event.target.closest(".assessment-record-card[data-id]");
  if (assessmentCard) {
    state.patientDetailAssessmentId = assessmentCard.dataset.id;
    state.patientDetailDailyId = "";
    renderPatientSection();
    return;
  }

  const card = event.target.closest(".patient-card[data-patient-id]");
  if (card) {
    state.patientDetailNo = card.dataset.patientId;
    state.patientDetailAdmissionId = "";
    state.patientDetailDailyId = "";
    state.patientDetailAssessmentId = "";
    state.patientDetailImagingPreviewId = "";
    state.admissionImagingPickerOpen = false;
    renderPatientSection();
  }
}

function renderAdmissionSection() {
  if (!state.patients.find((item) => item.admissionNo === state.selectedPatientNo)) {
    state.selectedPatientNo = state.patients[0]?.admissionNo || "";
  }

  el.admissionPatientSelect.innerHTML = state.patients.length
    ? state.patients
      .map((item) => `<option value="${esc(item.admissionNo)}">${esc(item.admissionNo)} - ${esc(item.name)}</option>`)
      .join("")
    : `<option value="">暂无病人</option>`;
  el.admissionPatientSelect.value = state.selectedPatientNo;

  const admissions = state.admissions.filter((item) => item.admissionNo === state.selectedPatientNo);
  if (!admissions.find((item) => item._id === state.selectedAdmissionId)) {
    state.selectedAdmissionId = admissions[0]?._id || "";
  }

  el.admissionStats.innerHTML = [
    statItem("入院记录", admissions.length),
    statItem("日常记录", state.dailyRecords.filter((item) => item.admissionId === state.selectedAdmissionId).length)
  ].join("");

  el.admissionList.innerHTML = admissions.length
    ? admissions.map(renderAdmissionCard).join("")
    : `<div class="empty">当前病人暂无入院记录</div>`;

  renderDailyList();
}

function renderAdmissionCard(admission) {
  const visibleFields = state.schemas.admission.filter((field) => isFieldVisibleInList("admission", field));
  const fields = visibleFields.length
    ? visibleFields.map((field) => fieldItem(field.label, formatFieldValue(field, admission[field.key]), field.type === "textarea")).join("")
    : fieldItem("提示", "当前未配置列表显示字段，请在字段配置中开启");
  return `
    <article class="entity-card">
      <div class="entity-head">
        <div class="entity-title">${esc(admission.admitDate || "未填写入院日期")}</div>
        <span class="entity-tag ${admission._id === state.selectedAdmissionId ? "active" : ""}">
          ${admission._id === state.selectedAdmissionId ? "已选中" : "可选择"}
        </span>
      </div>
      <div class="field-grid">${fields}</div>
      <div class="card-actions">
        <button class="mini-btn pick" data-action="pick-admission" data-id="${esc(admission._id)}">选择</button>
        <button class="mini-btn edit" data-action="edit-admission" data-id="${esc(admission._id)}">编辑</button>
        <button class="mini-btn delete" data-action="delete-admission" data-id="${esc(admission._id)}">删除</button>
      </div>
    </article>
  `;
}

function handleAdmissionActions(event) {
  const btn = event.target.closest("button");
  if (!btn) return;

  const action = btn.dataset.action;
  const id = btn.dataset.id;

  if (action === "pick-admission") {
    state.selectedAdmissionId = id;
    renderAdmissionSection();
    showToast("已切换到该入院记录");
    return;
  }

  if (action === "edit-admission") {
    editAdmissionById(id);
    return;
  }

  if (action === "delete-admission") {
    deleteAdmissionById(id);
  }
}

function renderDailyList() {
  const rows = state.dailyRecords.filter((item) => item.admissionId === state.selectedAdmissionId);
  el.dailyList.innerHTML = rows.length
    ? rows.map(renderDailyCard).join("")
    : `<div class="empty">当前入院记录暂无日常记录</div>`;
}

function renderDailyCard(row) {
  const visibleFields = state.schemas.daily.filter((field) => isFieldVisibleInList("daily", field));
  const fields = visibleFields.length
    ? visibleFields.map((field) => fieldItem(field.label, formatFieldValue(field, row[field.key]), field.type === "textarea")).join("")
    : fieldItem("提示", "当前未配置列表显示字段，请在字段配置中开启");
  return `
    <article class="entity-card">
      <div class="entity-head">
        <div class="entity-title">${esc(row.recordDate || "未填写日期")}</div>
        <span class="entity-tag">日常记录</span>
      </div>
      <div class="field-grid">${fields}</div>
      <div class="card-actions">
        <button class="mini-btn edit" data-action="edit-daily" data-id="${esc(row._id)}">编辑</button>
        <button class="mini-btn delete" data-action="delete-daily" data-id="${esc(row._id)}">删除</button>
      </div>
    </article>
  `;
}

function handleDailyActions(event) {
  const btn = event.target.closest("button");
  if (!btn) return;

  const action = btn.dataset.action;
  const id = btn.dataset.id;

  if (action === "edit-daily") {
    editDailyById(id);
    return;
  }

  if (action === "delete-daily") {
    deleteDailyById(id);
  }
}

function editAdmissionById(id) {
  const row = state.admissions.find((item) => item._id === id);
  if (!row) return;
  state.selectedPatientNo = row.admissionNo;
  openAdmissionModal("编辑入院记录", row, true);
}

function deleteAdmissionById(id) {
  const row = state.admissions.find((item) => item._id === id);
  if (!confirm("确认删除该入院记录及其日常记录吗？")) return;
  if (row) {
    state.selectedPatientNo = row.admissionNo;
  }

  state.admissions = state.admissions.filter((item) => item._id !== id);
  state.dailyRecords = state.dailyRecords.filter((item) => item.admissionId !== id);
  if (state.admissionAssessments) {
    delete state.admissionAssessments[id];
  }
  if (state.admissionImaging) {
    delete state.admissionImaging[id];
  }

  if (state.selectedAdmissionId === id) {
    state.selectedAdmissionId = "";
  }
  if (state.patientDetailAdmissionId === id) {
    state.patientDetailAdmissionId = "";
    state.patientDetailAssessmentId = "";
    state.patientDetailImagingPreviewId = "";
    state.admissionImagingPickerOpen = false;
    closeAdmissionImagingPreview();
    syncAdmissionImagingSourceRow();
  }
  state.patientDetailDailyId = "";

  persistDataState();
  renderAdmissionSection();
  if (state.patientDetailNo) renderPatientSection();
  showToast("入院记录已删除");
}

function editDailyById(id) {
  const row = state.dailyRecords.find((item) => item._id === id);
  if (!row) return;
  state.selectedAdmissionId = row.admissionId;
  openDailyModal("编辑日常记录", row, true);
}

function deleteDailyById(id) {
  if (!confirm("确认删除该条日常记录吗？")) return;
  state.dailyRecords = state.dailyRecords.filter((item) => item._id !== id);
  if (state.patientDetailDailyId === id) {
    state.patientDetailDailyId = "";
  }
  persistDataState();
  renderAdmissionSection();
  if (state.patientDetailNo) renderPatientSection();
  showToast("日常记录已删除");
}

function renderTemplateSection() {
  normalizeTemplateSelection();
  const diseases = state.templates;
  const searchKeyword = String(state.templateDiseaseSearchQuery || "").trim().toLowerCase();
  const filteredDiseases = searchKeyword
    ? diseases.filter((disease) => {
      const nameText = String(disease?.diseaseName || "").toLowerCase();
      const codeText = String(disease?.diseaseCode || "").toLowerCase();
      return nameText.includes(searchKeyword) || codeText.includes(searchKeyword);
    })
    : diseases;
  let selectedDisease = getSelectedTemplateDisease();
  let selectedVersion = getSelectedTemplateVersion();

  if (state.templateView === "config" && (!selectedDisease || !selectedVersion)) {
    state.templateView = "disease";
    state.templateSelectedVersionId = "";
  }

  selectedDisease = getSelectedTemplateDisease();
  selectedVersion = getSelectedTemplateVersion();
  const versionCount = diseases.reduce((sum, disease) => sum + (disease.versions?.length || 0), 0);

  el.templateDiseasePane.classList.toggle("hidden", state.templateView !== "disease");
  el.templateVersionPane.classList.add("hidden");
  el.templateConfigPane.classList.toggle("hidden", state.templateView !== "config");

  if (state.activeModule === "template") {
    refreshPageHeader();
  }

  el.templateStats.innerHTML = [
    statItem("\u75c5\u79cd\u6a21\u677f", diseases.length),
    statItem("\u7248\u672c\u6570\u91cf", versionCount)
  ].join("");
  if (el.templateDiseaseSearch) {
    const currentValue = String(el.templateDiseaseSearch.value || "");
    const targetValue = String(state.templateDiseaseSearchQuery || "");
    if (currentValue !== targetValue) {
      el.templateDiseaseSearch.value = targetValue;
    }
  }

  if (state.templateView === "disease") {
    if (!diseases.length) {
      el.templateDiseaseList.innerHTML = `<div class="empty">\u6682\u65e0\u75c5\u79cd\u6a21\u677f\uff0c\u8bf7\u5148\u65b0\u589e\u75c5\u79cd</div>`;
      return;
    }
    el.templateDiseaseList.innerHTML = filteredDiseases.length
      ? filteredDiseases
        .map((disease) =>
          renderTemplateDiseaseCard(
            disease,
            disease.id === state.templateExpandedDiseaseId,
            disease.id === state.templateSelectedDiseaseId
          ))
        .join("")
      : `<div class="empty">\u672a\u627e\u5230\u5339\u914d\u7684\u75c5\u79cd\u6a21\u677f\uff0c\u8bf7\u68c0\u67e5\u540d\u79f0\u6216\u7f16\u7801</div>`;
    return;
  }

  if (!selectedDisease) {
    el.templateItemList.innerHTML = `<div class="empty">\u8bf7\u5148\u9009\u62e9\u7248\u672c\u540e\u914d\u7f6e\u6d4b\u8bc4\u9879</div>`;
    el.templateGradeList.innerHTML = `<div class="empty">\u8bf7\u5148\u9009\u62e9\u7248\u672c\u540e\u914d\u7f6e\u5206\u7ea7\u533a\u95f4</div>`;
    el.addTemplateItemBtn.disabled = true;
    el.addTemplateGradeBtn.disabled = true;
    return;
  }

  if (!selectedVersion) {
    el.templateItemList.innerHTML = `<div class="empty">\u8bf7\u5148\u9009\u62e9\u7248\u672c\u540e\u914d\u7f6e\u6d4b\u8bc4\u9879</div>`;
    el.templateGradeList.innerHTML = `<div class="empty">\u8bf7\u5148\u9009\u62e9\u7248\u672c\u540e\u914d\u7f6e\u5206\u7ea7\u533a\u95f4</div>`;
    el.addTemplateItemBtn.disabled = true;
    el.addTemplateGradeBtn.disabled = true;
    return;
  }

  el.addTemplateItemBtn.disabled = false;
  el.addTemplateGradeBtn.disabled = false;
  el.templateItemTitle.textContent = `${selectedVersion.versionName} \u00b7 \u6d4b\u8bc4\u9879\u914d\u7f6e`;

  const items = selectedVersion.items || [];
  const gradeRules = [...(selectedVersion.gradeRules || [])].sort((a, b) => Number(a.min || 0) - Number(b.min || 0));
  selectedVersion.gradeRules = gradeRules;

  el.templateItemList.innerHTML = items.length
    ? items.map((item) => renderTemplateItemCard(item)).join("")
    : `<div class="empty">\u5f53\u524d\u7248\u672c\u6682\u65e0\u6d4b\u8bc4\u9879\uff0c\u8bf7\u5148\u65b0\u589e</div>`;
  el.templateGradeList.innerHTML = gradeRules.length
    ? gradeRules.map((rule) => renderTemplateGradeCard(rule)).join("")
    : `<div class="empty">\u5f53\u524d\u7248\u672c\u6682\u65e0\u7b49\u7ea7\u533a\u95f4\uff0c\u8bf7\u5148\u65b0\u589e</div>`;

}

function getTemplateDiseaseFieldValue(disease, field) {
  if (!disease || !field) return "";
  if (field.key === "versionCount") return (disease.versions || []).length;
  if (field.key === "itemCount") {
    return (disease.versions || []).reduce((sum, version) => sum + ((version.items || []).length), 0);
  }
  return disease[field.key];
}

function getTemplateVersionFieldValue(version, field) {
  if (!version || !field) return "";
  if (field.key === "itemCount") return (version.items || []).length;
  if (field.key === "optionCount") {
    return (version.items || []).reduce((sum, item) => sum + ((item.options || []).length), 0);
  }
  if (field.key === "gradeCount") return (version.gradeRules || []).length;
  return version[field.key];
}

function renderTemplateDiseaseCard(disease, expanded, active) {
  const versions = disease.versions || [];
  const schema = state.schemas.templateDisease || [];
  const visibleFields = schema.filter((field) => isFieldVisibleInList("templateDisease", field));
  const fieldHtml = visibleFields.length
    ? visibleFields
      .map((field) =>
        fieldItem(field.label, formatFieldValue(field, getTemplateDiseaseFieldValue(disease, field)), field.type === "textarea"))
      .join("")
    : fieldItem("提示", "当前未配置列表显示字段，请在字段配置中开启");
  const versionList = expanded
    ? (versions.length
      ? versions
        .map((version) =>
          renderTemplateVersionCard(
            version,
            version.id === state.templateSelectedVersionId && disease.id === state.templateSelectedDiseaseId,
            disease.id
          ))
        .join("")
      : `<div class="empty compact">\u5f53\u524d\u75c5\u79cd\u6682\u65e0\u7248\u672c\uff0c\u8bf7\u5148\u65b0\u589e\u7248\u672c</div>`)
    : "";
  const versionHeader = expanded
    ? `
      <div class="template-version-head">
        <span>\u7248\u672c\u5217\u8868</span>
        <button class="mini-btn ghost" data-action="add-template-version" data-id="${esc(disease.id)}">\u65b0\u589e\u7248\u672c</button>
      </div>
    `
    : "";
  return `
    <article class="entity-card template-disease-card template-nav-card ${active ? "active" : ""} ${expanded ? "expanded" : ""}" data-id="${esc(disease.id)}">
      <div class="entity-head">
        <div class="entity-title">${esc(disease.diseaseName || "\u672a\u547d\u540d\u75c5\u79cd")}</div>
        <div class="field-head-actions">
          <button class="mini-btn edit" data-action="edit-template-disease" data-id="${esc(disease.id)}">\u7f16\u8f91</button>
          <button class="mini-btn delete" data-action="delete-template-disease" data-id="${esc(disease.id)}">\u5220\u9664</button>
          <span class="template-chevron-inline ${expanded ? "expanded" : ""}" aria-hidden="true">\u203a</span>
        </div>
      </div>
      <div class="field-grid">${fieldHtml}</div>
      ${expanded
        ? `<div class="template-version-wrap">${versionHeader}${versionList}</div>`
        : ""}
    </article>
  `;
}

function renderTemplateVersionCard(version, active, diseaseId = "") {
  const schema = state.schemas.templateVersion || [];
  const visibleFields = schema.filter((field) => isFieldVisibleInList("templateVersion", field));
  const fieldHtml = visibleFields.length
    ? visibleFields
      .map((field) =>
        fieldItem(field.label, formatFieldValue(field, getTemplateVersionFieldValue(version, field)), field.type === "textarea"))
      .join("")
    : fieldItem("提示", "当前未配置列表显示字段，请在字段配置中开启");
  return `
    <article class="entity-card template-version-card template-nav-card ${active ? "active" : ""}" data-id="${esc(version.id)}" data-disease-id="${esc(diseaseId)}">
      <div class="entity-head">
        <div class="entity-title">${esc(version.versionName || "\u672a\u547d\u540d\u7248\u672c")}</div>
        <div class="field-head-actions">
          <button class="mini-btn edit" data-action="edit-template-version" data-id="${esc(version.id)}" data-disease-id="${esc(diseaseId)}">\u7f16\u8f91</button>
          <button class="mini-btn delete" data-action="delete-template-version" data-id="${esc(version.id)}" data-disease-id="${esc(diseaseId)}">\u5220\u9664</button>
          <span class="template-chevron-inline" aria-hidden="true">\u203a</span>
        </div>
      </div>
      <div class="field-grid">${fieldHtml}</div>
    </article>
  `;
}

function renderTemplateItemCard(item) {
  const options = item.options || [];
  const optionSummary = options.length
    ? options.map((opt) => `<span class="option-chip">${esc(opt.label)} · ${esc(String(opt.score))}分</span>`).join("")
    : `<span class="option-chip ghost">暂无选项</span>`;
  return `
    <article class="entity-card template-item-card">
      <div class="entity-head">
        <div class="entity-title">${esc(item.name || "未命名测评项")}</div>
        <div class="field-head-actions">
          <button class="mini-btn edit" data-action="edit-template-item" data-id="${esc(item.id)}">编辑</button>
          <button class="mini-btn delete" data-action="delete-template-item" data-id="${esc(item.id)}">删除</button>
        </div>
      </div>
      <div class="option-chip-row">${optionSummary}</div>
    </article>
  `;
}

function renderTemplateGradeCard(rule) {
  return `
    <article class="entity-card template-grade-card">
      <div class="entity-head">
        <div class="entity-title">${esc(rule.level || "未命名等级")}</div>
        <div class="field-head-actions">
          <span class="entity-tag">${esc(String(rule.min))} - ${esc(String(rule.max))} 分</span>
          <button class="mini-btn edit" data-action="edit-template-grade" data-id="${esc(rule.id)}">编辑</button>
          <button class="mini-btn delete" data-action="delete-template-grade" data-id="${esc(rule.id)}">删除</button>
        </div>
      </div>
      <div class="field-grid">
        ${fieldItem("评分区间", `${rule.min} - ${rule.max}`)}
        ${fieldItem("判定等级", rule.level || "-")}
        ${fieldItem("说明", rule.note || "-", true)}
      </div>
    </article>
  `;
}

function getAdmissionAssessmentStore(admissionId) {
  if (!state.admissionAssessments || typeof state.admissionAssessments !== "object") {
    state.admissionAssessments = {};
  }
  if (!state.admissionAssessments[admissionId]) {
    state.admissionAssessments[admissionId] = {
      records: []
    };
  }
  return state.admissionAssessments[admissionId];
}

function normalizeAdmissionAssessmentStore(admissionId) {
  const store = getAdmissionAssessmentStore(admissionId);
  if (!Array.isArray(store.records)) {
    store.records = [];
  }
  store.records = store.records
    .filter((record) => record && typeof record === "object")
    .map((record) => ({
      id: record.id || uid("assr"),
      diseaseId: typeof record.diseaseId === "string" ? record.diseaseId : "",
      versionId: typeof record.versionId === "string" ? record.versionId : "",
      selections: record.selections && typeof record.selections === "object" ? record.selections : {},
      createdAt: record.createdAt || new Date().toISOString()
    }));
  return store;
}

function normalizeAssessmentDraft(draft) {
  if (!draft) return null;
  const diseases = Array.isArray(state.templates) ? state.templates : [];
  if (!diseases.length) {
    draft.diseaseId = "";
    draft.versionId = "";
    draft.selections = {};
    return draft;
  }

  if (!diseases.some((item) => item.id === draft.diseaseId)) {
    draft.diseaseId = diseases[0].id;
    draft.versionId = "";
    draft.selections = {};
  }

  const disease = diseases.find((item) => item.id === draft.diseaseId);
  disease.versions = Array.isArray(disease.versions) ? disease.versions : [];
  if (!disease.versions.some((item) => item.id === draft.versionId)) {
    draft.versionId = disease.versions[0]?.id || "";
    draft.selections = {};
  }

  const version = disease.versions.find((item) => item.id === draft.versionId);
  if (version) {
    const itemIds = new Set((version.items || []).map((item) => item.id));
    draft.selections = Object.fromEntries(
      Object.entries(draft.selections || {}).filter(([key]) => itemIds.has(key))
    );
  } else {
    draft.selections = {};
  }

  return draft;
}

function createAssessmentDraft(admissionId) {
  const diseases = Array.isArray(state.templates) ? state.templates : [];
  if (!diseases.length) return null;
  const store = normalizeAdmissionAssessmentStore(admissionId);
  const sorted = [...store.records].sort((a, b) => String(b.createdAt || "").localeCompare(String(a.createdAt || "")));
  const latest = sorted[0];
  const draft = {
    id: uid("assr"),
    admissionId,
    diseaseId: latest?.diseaseId || diseases[0]?.id || "",
    versionId: latest?.versionId || "",
    selections: {},
    createdAt: new Date().toISOString()
  };
  return normalizeAssessmentDraft(draft);
}

function getCurrentAdmissionForAssessment() {
  const admissionId = state.patientDetailAdmissionId;
  if (!admissionId) return null;
  const admission = state.admissions.find((item) => item._id === admissionId);
  if (!admission) return null;
  return admission;
}

function openEditAdmissionAssessmentModal(recordId) {
  if (!recordId) return;
  const admission = getCurrentAdmissionForAssessment();
  if (!admission) return;
  const store = normalizeAdmissionAssessmentStore(admission._id);
  const record = (store.records || []).find((item) => item.id === recordId);
  if (!record) {
    alert("未找到对应测评记录。");
    return;
  }
  openAssessmentModalShell(admission, record);
}

function deleteAdmissionAssessmentRecord(recordId) {
  if (!recordId) return;
  const admission = getCurrentAdmissionForAssessment();
  if (!admission) return;
  if (!confirm("确认删除该测评记录吗？")) return;
  const store = normalizeAdmissionAssessmentStore(admission._id);
  const before = store.records.length;
  store.records = store.records.filter((item) => item.id !== recordId);
  if (store.records.length === before) return;
  if (state.patientDetailAssessmentId === recordId) {
    state.patientDetailAssessmentId = "";
  }
  persistDataState();
  renderPatientSection();
  showToast("测评记录已删除");
}

function renderAdmissionAssessmentSection(admission) {
  if (!admission || !el.admissionTemplateSummary) return;
  const store = normalizeAdmissionAssessmentStore(admission._id);
  const records = [...store.records].sort((a, b) => String(b.createdAt || "").localeCompare(String(a.createdAt || "")));
  const diseases = Array.isArray(state.templates) ? state.templates : [];

  if (!records.length) {
    el.admissionTemplateSummary.innerHTML = diseases.length
      ? `<div class="empty">暂无测评记录，点击右上角新增测评</div>`
      : `<div class="empty">暂无测评模板</div>`;
    return;
  }

  el.admissionTemplateSummary.innerHTML = records
    .map((record) => renderAssessmentRecordCard(record))
    .join("");
}

function getAdmissionImagingItems(admissionId) {
  if (!admissionId) return [];
  if (!state.admissionImaging || typeof state.admissionImaging !== "object") {
    state.admissionImaging = {};
  }
  const normalized = normalizeImageItems(state.admissionImaging[admissionId] || []);
  state.admissionImaging[admissionId] = normalized;
  return normalized;
}

function setAdmissionImagingItems(admissionId, items) {
  if (!admissionId) return [];
  if (!state.admissionImaging || typeof state.admissionImaging !== "object") {
    state.admissionImaging = {};
  }
  const normalized = normalizeImageItems(items);
  if (normalized.length) {
    state.admissionImaging[admissionId] = normalized;
  } else {
    delete state.admissionImaging[admissionId];
  }
  return normalized;
}

function removeAdmissionImagingItem(admissionId, imageId) {
  if (!admissionId || !imageId) return false;
  const items = getAdmissionImagingItems(admissionId);
  const next = items.filter((item) => item.id !== imageId);
  if (next.length === items.length) return false;
  setAdmissionImagingItems(admissionId, next);
  return true;
}

function syncAdmissionImagingSourceRow() {
  if (!el.admissionImagingSourceRow) return;
  const visible = state.activeModule === "patient"
    && !!state.patientDetailAdmissionId
    && !state.patientDetailDailyId
    && !state.patientDetailAssessmentId;
  el.admissionImagingSourceRow.classList.toggle("hidden", !visible);
}

function handleAdmissionImagingFileInput(input) {
  const files = Array.from(input?.files || []);
  const admissionId = state.patientDetailAdmissionId;
  if (!files.length || !admissionId) {
    if (input) input.value = "";
    return;
  }

  readFilesAsDataUrls(files).then((items) => {
    if (!items.length) {
      showToast("未读取到有效影像");
      return;
    }
    const merged = getAdmissionImagingItems(admissionId).concat(items);
    setAdmissionImagingItems(admissionId, merged);
    state.patientDetailImagingPreviewId = items[0].id || state.patientDetailImagingPreviewId;
    persistDataState();
    if (state.activeModule === "patient" && state.patientDetailAdmissionId === admissionId) {
      renderPatientSection();
    } else {
      renderAll();
    }
    showToast(`已新增${items.length}张影像`);
  }).finally(() => {
    if (input) input.value = "";
  });
}

function renderAdmissionImagingSection(admission) {
  if (!admission || !el.admissionImagingList) return;
  const items = getAdmissionImagingItems(admission._id);
  syncAdmissionImagingSourceRow();

  if (!items.length) {
    state.patientDetailImagingPreviewId = "";
    el.admissionImagingList.innerHTML = `<div class="empty">暂无影像资料，可使用拍照或相册上传</div>`;
    return;
  }

  if (!items.some((item) => item.id === state.patientDetailImagingPreviewId)) {
    state.patientDetailImagingPreviewId = items[0].id;
  }
  const activeId = state.patientDetailImagingPreviewId;

  el.admissionImagingList.innerHTML = `
    <article class="entity-card admission-imaging-card">
      <div class="admission-imaging-preview-meta">
        <span>点击缩略图查看原图</span>
        <span class="entity-tag">共 ${esc(String(items.length))} 张</span>
      </div>
      <div class="admission-imaging-thumb-strip">
        ${items.map((item, index) => renderAdmissionImagingThumb(item, item.id === activeId, index)).join("")}
      </div>
    </article>
  `;
}

function renderAdmissionImagingThumb(item, active, index) {
  const title = item.name || `影像${index + 1}`;
  return `
    <div class="admission-imaging-thumb${active ? " active" : ""}">
      <button class="admission-imaging-thumb-hit" type="button" data-action="select-admission-image" data-id="${esc(item.id)}" aria-label="预览${esc(title)}">
        <img src="${esc(item.src)}" alt="${esc(title)}">
      </button>
      <button class="admission-imaging-thumb-remove" type="button" data-action="remove-admission-image" data-id="${esc(item.id)}" aria-label="删除${esc(title)}">×</button>
    </div>
  `;
}

function renderAdmissionImagingThumbActiveState(activeId) {
  if (!el.admissionImagingList) return;
  el.admissionImagingList.querySelectorAll(".admission-imaging-thumb").forEach((thumb) => {
    const hitBtn = thumb.querySelector(".admission-imaging-thumb-hit[data-id]");
    thumb.classList.toggle("active", !!hitBtn && hitBtn.dataset.id === activeId);
  });
}

function openAdmissionImagingPreview(imageId) {
  if (!el.imagingPreviewOverlay || !el.imagingPreviewImage || !state.patientDetailAdmissionId || !imageId) return;
  const items = getAdmissionImagingItems(state.patientDetailAdmissionId);
  const target = items.find((item) => item.id === imageId);
  if (!target) return;
  el.imagingPreviewImage.src = target.src;
  el.imagingPreviewImage.alt = target.name || "影像原图";
  if (el.imagingPreviewCaption) {
    const fallbackName = `影像 ${items.findIndex((item) => item.id === imageId) + 1}`;
    el.imagingPreviewCaption.textContent = target.name || fallbackName;
  }
  el.imagingPreviewOverlay.classList.remove("hidden");
}

function closeAdmissionImagingPreview() {
  if (!el.imagingPreviewOverlay) return;
  el.imagingPreviewOverlay.classList.add("hidden");
  if (el.imagingPreviewImage) {
    el.imagingPreviewImage.removeAttribute("src");
  }
  if (el.imagingPreviewCaption) {
    el.imagingPreviewCaption.textContent = "";
  }
}

function renderAdmissionAssessmentModalItem(admissionId, item, selections, config = {}) {
  const readonly = !!config.readonly;
  const itemNameSeed = config.nameSeed || admissionId;
  const selectedId = selections?.[item.id] || "";
  const options = item.options || [];
  const optionHtml = options.length
    ? options.map((opt) => {
      const checked = opt.id === selectedId ? "checked" : "";
      const readonlyAttrs = readonly
        ? "disabled"
        : `data-action="admission-assessment-option" data-admission-id="${esc(admissionId)}" data-item-id="${esc(item.id)}"`;
      const optionClass = `assessment-option${readonly ? " readonly" : ""}`;
      return `
        <label class="${optionClass}">
          <input type="radio" name="assess_${esc(itemNameSeed)}_${esc(item.id)}" value="${esc(opt.id)}"
            ${readonlyAttrs} ${checked}>
          <span class="label">${esc(opt.label)}</span>
          <span class="score">${esc(String(opt.score))}分</span>
        </label>
      `;
    }).join("")
    : `<div class="empty compact">暂无评分选项</div>`;

  return `
    <article class="entity-card assessment-item-card">
      <div class="entity-head">
        <div class="entity-title">${esc(item.name || "未命名测评项")}</div>
      </div>
      <div class="assessment-options">${optionHtml}</div>
    </article>
  `;
}

function getAssessmentRecordMeta(record) {
  const diseases = Array.isArray(state.templates) ? state.templates : [];
  const disease = diseases.find((item) => item.id === record.diseaseId);
  const versions = disease?.versions || [];
  const version = versions.find((item) => item.id === record.versionId) || null;
  const result = version ? calculateAssessmentResult(version, record.selections) : null;
  return {
    disease,
    version,
    result,
    diseaseName: disease?.diseaseName || "模板已删除",
    versionName: version?.versionName || "版本不可用"
  };
}

function renderAssessmentRecordCard(record) {
  const meta = getAssessmentRecordMeta(record);
  const dateText = formatDateTime(record.createdAt);
  const scaleCore = (meta.version && meta.result)
    ? renderAssessmentScoreScale(meta.version, meta.result, { compact: true, hideLabels: false, labelMode: "full" })
    : "";
  const scaleHtml = scaleCore || `<div class="assessment-scale-empty">当前模板未配置区间，无法展示进度条</div>`;
  return `
    <article class="entity-card assessment-record-card overview-click-card" data-id="${esc(record.id)}">
      <div class="entity-head">
        <div class="entity-title">${esc(meta.diseaseName)}</div>
        <div class="field-head-actions assessment-record-actions overview-card-actions">
          <button class="mini-btn edit overview-action-btn" data-action="edit-assessment-record" data-id="${esc(record.id)}">编辑</button>
          <button class="mini-btn delete overview-action-btn" data-action="delete-assessment-record" data-id="${esc(record.id)}">删除</button>
        </div>
      </div>
      <div class="field-grid assessment-meta-grid overview-field-grid">
        ${fieldItem("模板版本", meta.versionName)}
        ${fieldItem("测评时间", dateText)}
      </div>
      <div class="assessment-record-scale">
        ${scaleHtml}
      </div>
      <span class="patient-chevron" aria-hidden="true">›</span>
    </article>
  `;
}

function renderAssessmentDetailView(record, admission) {
  const meta = getAssessmentRecordMeta(record);
  const diseases = Array.isArray(state.templates) ? state.templates : [];
  const selectedDisease = diseases.find((item) => item.id === record.diseaseId) || null;
  const versions = selectedDisease?.versions || [];
  const selectedVersion = versions.find((item) => item.id === record.versionId) || null;
  const result = meta.result;
  const diseaseOptions = selectedDisease
    ? diseases.map((row) => {
      const selected = row.id === record.diseaseId ? "selected" : "";
      return `<option value="${esc(row.id)}" ${selected}>${esc(row.diseaseName || "未命名病种")}</option>`;
    }).join("")
    : `<option value="">模板已删除</option>`;
  const versionOptions = selectedVersion
    ? versions.map((row) => {
      const selected = row.id === record.versionId ? "selected" : "";
      return `<option value="${esc(row.id)}" ${selected}>${esc(row.versionName || "未命名版本")}</option>`;
    }).join("")
    : `<option value="">版本不可用</option>`;

  const items = meta.version?.items || [];
  const resultHtml = meta.version
    ? renderAdmissionAssessmentResult(meta.version, record.selections)
    : renderEmptyAssessmentResult("该测评模板已被删除");
  const scoreScaleHtml = (meta.version && result)
    ? renderAssessmentScoreScale(meta.version, result)
    : "";
  const itemHtml = items.length
    ? items.map((item) =>
      renderAdmissionAssessmentModalItem(admission?._id || "detail", item, record.selections, {
        readonly: true,
        nameSeed: `detail_${record.id}`
      })).join("")
    : `<div class="empty">暂无测评项</div>`;

  return `
    <div class="assessment-modal-body assessment-detail-readonly">
      <div class="assessment-summary">
        <div class="summary-main">
          <div class="summary-title">住院测评明细</div>
          <div class="summary-sub">${esc(admission?.admitDate || "未填写入院日期")} · ${esc(admission?.diagnosis || "未填写诊断")}</div>
        </div>
        <div class="summary-score">
          <div class="label">当前得分</div>
          <div class="value">${meta.version ? result.score.toFixed(1) : "-"}</div>
          <div class="tag ${result?.level ? "active" : ""}">${esc(result?.level || "待评估")}</div>
        </div>
      </div>

      <section class="assessment-step">
        <div class="assessment-step-head">
          <span class="step-index">01</span>
          <div>
            <div class="step-title">模板与版本</div>
            <div class="step-sub">当前测评使用的规则（只读）</div>
          </div>
        </div>
        <div class="control-row">
          <select disabled>
            ${diseaseOptions}
          </select>
          <select disabled>
            ${versionOptions}
          </select>
        </div>
        <div class="field-grid">
          ${fieldItem("测评时间", formatDateTime(record.createdAt))}
          ${fieldItem("完成项", meta.result ? `${meta.result.filledCount}/${meta.result.totalCount}` : "-")}
          ${fieldItem("患病等级", meta.result?.level || "待评估")}
        </div>
      </section>

      <section class="assessment-step">
        <div class="assessment-step-head">
          <span class="step-index">02</span>
          <div>
            <div class="step-title">评分选项</div>
            <div class="step-sub">仅展示已保存选项，不可修改</div>
          </div>
        </div>
        <div class="assessment-item-list">${itemHtml}</div>
      </section>

      <section class="assessment-step">
        <div class="assessment-step-head">
          <span class="step-index">03</span>
          <div>
            <div class="step-title">评分结果</div>
            <div class="step-sub">自动汇总得分与区间</div>
          </div>
          <div class="field-head-actions overview-card-actions">
            <button class="mini-btn edit overview-action-btn" data-action="edit-assessment-record" data-id="${esc(record.id)}">编辑</button>
            <button class="mini-btn delete overview-action-btn" data-action="delete-assessment-record" data-id="${esc(record.id)}">删除</button>
          </div>
        </div>
        <div class="entity-card assessment-result-card">
          ${scoreScaleHtml}
          ${resultHtml}
        </div>
      </section>
    </div>
  `;
}

function renderAssessmentScoreScale(version, result, options = {}) {
  const hideLabels = !!options.hideLabels;
  const compact = !!options.compact;
  const labelMode = options.labelMode === "range" ? "range" : "full";
  const rawRules = Array.isArray(version?.gradeRules) ? version.gradeRules : [];
  const rules = rawRules
    .map((rule) => ({
      min: Number(rule?.min),
      max: Number(rule?.max),
      level: String(rule?.level || "").trim()
    }))
    .filter((rule) => Number.isFinite(rule.min) && Number.isFinite(rule.max) && rule.max >= rule.min)
    .sort((a, b) => a.min - b.min);

  if (!rules.length) {
    return "";
  }

  const palette = ["#8fbaf2", "#84d6c0", "#f5c97c", "#f2a0a0", "#b8abf7", "#97d2e5"];
  const domainMin = Math.min(...rules.map((rule) => rule.min));
  let domainMax = Math.max(...rules.map((rule) => rule.max));
  if (!Number.isFinite(domainMax) || domainMax <= domainMin) {
    domainMax = domainMin + 1;
  }
  const totalSpan = (domainMax - domainMin) + 1;
  const score = Number.isFinite(Number(result?.score)) ? Number(result.score) : 0;
  const normalized = Math.max(0, Math.min(1, (score - domainMin) / (domainMax - domainMin)));
  const markerPct = normalized * 100;
  const markerClass = markerPct <= 8 ? "left" : markerPct >= 92 ? "right" : "";

  const segmentsHtml = rules.map((rule, index) => {
    const span = Math.max((rule.max - rule.min) + 1, 1);
    const width = (span / totalSpan) * 100;
    const color = palette[index % palette.length];
    const active = score >= rule.min && score <= rule.max;
    return `<span class="assessment-scale-segment ${active ? "active" : ""}" style="--segment-width:${width.toFixed(4)}%;--segment-color:${color};"></span>`;
  }).join("");

  const labelsHtml = rules.map((rule, index) => {
    const span = Math.max((rule.max - rule.min) + 1, 1);
    const width = (span / totalSpan) * 100;
    const color = palette[index % palette.length];
    const active = score >= rule.min && score <= rule.max;
    const level = rule.level || `区间${index + 1}`;
    const labelText = labelMode === "range" ? `${rule.min}-${rule.max}` : `${level} ${rule.min}-${rule.max}`;
    return `
      <span class="assessment-scale-label-cell ${active ? "active" : ""}" style="--segment-width:${width.toFixed(4)}%;">
        <span class="assessment-scale-label-chip">
          <span class="dot" style="--dot-color:${color};"></span>
          <span class="text">${esc(labelText)}</span>
        </span>
      </span>
    `;
  }).join("");

  const labelsRowHtml = hideLabels
    ? ""
    : `<div class="assessment-scale-label-row">${labelsHtml}</div>`;

  return `
    <div class="assessment-scale ${compact ? "compact" : ""}">
      <div class="assessment-scale-track-wrap">
        <div class="assessment-scale-track">
          ${segmentsHtml}
        </div>
        <span class="assessment-scale-marker ${markerClass}" style="left:${markerPct.toFixed(2)}%;">
          <span class="marker-dot"></span>
          <span class="marker-label">${esc(score.toFixed(1))}</span>
        </span>
      </div>
      ${labelsRowHtml}
    </div>
  `;
}

function validateAssessmentDraftSelections(draft) {
  if (!draft || !draft.diseaseId || !draft.versionId) {
    return { ok: false, message: "请选择测评模板与版本后再保存。" };
  }
  const diseases = Array.isArray(state.templates) ? state.templates : [];
  const disease = diseases.find((item) => item.id === draft.diseaseId);
  const version = (disease?.versions || []).find((item) => item.id === draft.versionId);
  if (!version) {
    return { ok: false, message: "当前模板版本不可用，请重新选择后再保存。" };
  }

  const items = Array.isArray(version.items) ? version.items : [];
  if (!items.length) {
    return { ok: false, message: "当前版本暂无测评项，无法保存。" };
  }

  const missingConfig = [];
  const missingSelection = [];
  for (const item of items) {
    const options = Array.isArray(item.options) ? item.options : [];
    const itemName = item.name || "未命名测评项";
    if (!options.length) {
      missingConfig.push(itemName);
      continue;
    }
    const selectedId = draft.selections?.[item.id];
    if (!selectedId || !options.some((opt) => opt.id === selectedId)) {
      missingSelection.push(itemName);
    }
  }

  if (missingConfig.length) {
    return {
      ok: false,
      message: `以下测评项未配置评分选项：${missingConfig.slice(0, 3).join("、")}${missingConfig.length > 3 ? "等" : ""}。`
    };
  }
  if (missingSelection.length) {
    return {
      ok: false,
      message: `评分选项为必填，请补全：${missingSelection.slice(0, 3).join("、")}${missingSelection.length > 3 ? "等" : ""}。`
    };
  }
  return { ok: true };
}

function calculateAssessmentResult(version, selections) {
  const items = version?.items || [];
  const totalCount = items.length;
  let filledCount = 0;
  let totalScore = 0;

  for (const item of items) {
    const options = item.options || [];
    if (!options.length) continue;
    const selectedId = selections?.[item.id];
    const selectedOption = options.find((opt) => opt.id === selectedId);
    if (!selectedOption) continue;
    filledCount += 1;
    totalScore += Number(selectedOption.score || 0);
  }

  const rules = [...(version?.gradeRules || [])].sort((a, b) => Number(a.min || 0) - Number(b.min || 0));
  const hit = rules.find((rule) => totalScore >= Number(rule.min || 0) && totalScore <= Number(rule.max || 0));
  const rangeText = hit ? `${hit.min} - ${hit.max}` : "";

  return {
    score: Number.isFinite(totalScore) ? totalScore : 0,
    filledCount,
    totalCount,
    level: hit?.level || "",
    note: hit?.note || "",
    range: rangeText
  };
}

function renderAdmissionAssessmentResult(version, selections) {
  const result = calculateAssessmentResult(version, selections);
  return `
    <div class="entity-head">
      <div class="entity-title">评分结果</div>
      <span class="entity-tag ${result.level ? "active" : ""}">${esc(result.level || "待评估")}</span>
    </div>
    <div class="field-grid">
      ${fieldItem("综合得分", `${result.score.toFixed(1)}`)}
      ${fieldItem("完成项", `${result.filledCount}/${result.totalCount}`)}
      ${fieldItem("所在区间", result.range || "未命中等级区间")}
      ${fieldItem("患病等级", result.level || "-")}
      ${fieldItem("判定说明", result.note || "请选择每个测评项的评分选项后自动计算", true)}
    </div>
  `;
}

function renderEmptyAssessmentResult(message) {
  return `
    <div class="entity-head">
      <div class="entity-title">评分结果</div>
      <span class="entity-tag">待计算</span>
    </div>
    <div class="field-grid">
      ${fieldItem("综合得分", "-")}
      ${fieldItem("所在区间", "-")}
      ${fieldItem("患病等级", "-")}
      ${fieldItem("判定说明", message || "请先选择模板版本")}
    </div>
  `;
}

function openAdmissionAssessmentModal() {
  const admission = getCurrentAdmissionForAssessment();
  if (!admission) return;
  openAssessmentModalShell(admission);
}

function openAssessmentModalShell(admission, editingRecord = null) {
  const admissionId = admission._id;
  if (editingRecord) {
    assessmentDraftMode = "edit";
    assessmentDraftSourceId = editingRecord.id;
    assessmentDraft = normalizeAssessmentDraft({
      id: editingRecord.id,
      admissionId,
      diseaseId: editingRecord.diseaseId || "",
      versionId: editingRecord.versionId || "",
      selections: { ...(editingRecord.selections || {}) },
      createdAt: editingRecord.createdAt || new Date().toISOString()
    });
  } else {
    assessmentDraftMode = "create";
    assessmentDraftSourceId = "";
    assessmentDraft = createAssessmentDraft(admissionId);
  }

  if (!assessmentDraft) {
    alert("请先在测评模板中配置病种与版本。");
    return;
  }

  if (el.modalShell) {
    el.modalShell.classList.add("assessment-modal");
  }
  modalState.onSubmit = () => {
    if (!assessmentDraft || !assessmentDraft.diseaseId || !assessmentDraft.versionId) {
      alert("请选择测评模板与版本后再保存。");
      return false;
    }
    const store = normalizeAdmissionAssessmentStore(admissionId);
    const normalized = normalizeAssessmentDraft({
      id: assessmentDraft.id || assessmentDraftSourceId || uid("assr"),
      diseaseId: assessmentDraft.diseaseId,
      versionId: assessmentDraft.versionId,
      selections: { ...assessmentDraft.selections },
      createdAt: assessmentDraft.createdAt || new Date().toISOString()
    });
    if (!normalized) return false;
    const selectionCheck = validateAssessmentDraftSelections(normalized);
    if (!selectionCheck.ok) {
      alert(selectionCheck.message);
      return false;
    }

    if (assessmentDraftMode === "edit") {
      const index = store.records.findIndex((item) => item.id === assessmentDraftSourceId);
      if (index >= 0) {
        store.records[index] = normalized;
      } else {
        store.records.unshift(normalized);
      }
      if (state.patientDetailAssessmentId === assessmentDraftSourceId) {
        state.patientDetailAssessmentId = normalized.id;
      }
      showToast("测评记录已更新");
    } else {
      store.records.unshift(normalized);
      showToast("测评记录已新增");
    }

    persistDataState();
    if (state.patientDetailNo) {
      renderPatientSection();
    } else {
      renderAdmissionAssessmentSection(admission);
    }
    return true;
  };
  const editing = assessmentDraftMode === "edit";
  el.modalTitle.textContent = editing ? "修改住院测评" : "新增住院测评";
  if (el.modalSubtitle) {
    el.modalSubtitle.textContent = editing
      ? "调整模板与评分选项后保存，结果会即时刷新。"
      : "选择模板与版本，勾选评分选项后保存。";
  }
  el.modalForm.innerHTML = renderAdmissionAssessmentModal(admission);
  el.modalOverlay.classList.remove("hidden");
}

function renderAdmissionAssessmentModal(admission) {
  const diseases = Array.isArray(state.templates) ? state.templates : [];
  const assessment = normalizeAssessmentDraft(assessmentDraft);
  if (!assessment) return `<div class="empty">暂无测评模板</div>`;
  const disease = diseases.find((item) => item.id === assessment.diseaseId) || diseases[0];
  const versions = disease?.versions || [];
  const version = versions.find((item) => item.id === assessment.versionId) || null;
  const result = version ? calculateAssessmentResult(version, assessment.selections) : null;

  const diseaseOptions = diseases.length
    ? diseases.map((row) => {
      const selected = row.id === assessment.diseaseId ? "selected" : "";
      return `<option value="${esc(row.id)}" ${selected}>${esc(row.diseaseName || "未命名病种")}</option>`;
    }).join("")
    : `<option value="">暂无测评模板</option>`;
  const versionOptions = versions.length
    ? versions.map((row) => {
      const selected = row.id === assessment.versionId ? "selected" : "";
      return `<option value="${esc(row.id)}" ${selected}>${esc(row.versionName || "未命名版本")}</option>`;
    }).join("")
    : `<option value="">暂无版本</option>`;

  const itemsHtml = version?.items?.length
    ? version.items.map((item) => renderAdmissionAssessmentModalItem(admission._id, item, assessment.selections)).join("")
    : `<div class="empty">当前版本暂无测评项</div>`;
  const summaryScaleHtml = version
    ? renderAssessmentScoreScale(version, result, { compact: true, hideLabels: false, labelMode: "full" })
    : `<div class="assessment-scale-empty">请选择模板版本后展示区间进度</div>`;
  const editing = assessmentDraftMode === "edit";

  return `
    <div class="assessment-modal-body" data-admission-id="${esc(admission._id)}">
      <div class="assessment-summary assessment-summary-with-scale">
        <div class="summary-main">
          <div class="summary-title">${editing ? "住院测评修改" : "住院测评录入"}</div>
          <div class="summary-sub">${esc(admission.admitDate || "未填写入院日期")} · ${esc(admission.diagnosis || "未填写诊断")}</div>
        </div>
        <div class="summary-score">
          <div class="label">当前得分</div>
          <div class="value">${version ? result.score.toFixed(1) : "-"}</div>
          <div class="tag ${result?.level ? "active" : ""}">${esc(result?.level || "待评估")}</div>
        </div>
        <div class="summary-scale">
          ${summaryScaleHtml}
        </div>
      </div>

      <section class="assessment-step">
        <div class="assessment-step-head">
          <span class="step-index">01</span>
          <div>
            <div class="step-title">选择模板与版本</div>
            <div class="step-sub">决定评分规则与等级区间</div>
          </div>
        </div>
        <div class="control-row">
          <select data-action="admission-assessment-select" data-field="disease" data-admission-id="${esc(admission._id)}">
            ${diseaseOptions}
          </select>
          <select data-action="admission-assessment-select" data-field="version" data-admission-id="${esc(admission._id)}" ${versions.length ? "" : "disabled"}>
            ${versionOptions}
          </select>
        </div>
      </section>

      <section class="assessment-step">
        <div class="assessment-step-head">
          <span class="step-index">02</span>
          <div>
            <div class="step-title">评分选项</div>
            <div class="step-sub">每项必填，请逐项选择评分结果</div>
          </div>
        </div>
        <div class="assessment-item-list">${itemsHtml}</div>
      </section>
    </div>
  `;
}

function updateAdmissionAssessmentModal(admissionId) {
  const admission = state.admissions.find((item) => item._id === admissionId);
  if (!admission) return;
  el.modalForm.innerHTML = renderAdmissionAssessmentModal(admission);
}

function handleAdmissionAssessmentModalSelect(target) {
  const admissionId = target.dataset.admissionId || state.patientDetailAdmissionId;
  if (!admissionId || !assessmentDraft) return;
  const assessment = assessmentDraft;
  const field = target.dataset.field;
  const nextValue = target.value || "";

  if (field === "disease") {
    if (assessment.diseaseId !== nextValue) {
      assessment.diseaseId = nextValue;
      assessment.versionId = "";
      assessment.selections = {};
    }
  }

  if (field === "version") {
    if (assessment.versionId !== nextValue) {
      assessment.versionId = nextValue;
      assessment.selections = {};
    }
  }

  normalizeAssessmentDraft(assessment);
  updateAdmissionAssessmentModal(admissionId);
}

function handleAdmissionAssessmentModalOption(input) {
  const admissionId = input.dataset.admissionId;
  const itemId = input.dataset.itemId;
  if (!admissionId || !itemId || !assessmentDraft) return;
  const assessment = assessmentDraft;
  assessment.selections[itemId] = input.value || "";
  updateAdmissionAssessmentModal(admissionId);
}

function handleTemplateActions(event) {
  const btn = event.target.closest("button[data-action]");
  if (btn) {
    const action = btn.dataset.action;
    const id = btn.dataset.id;

    if (action === "edit-template-disease") {
      openEditTemplateDiseaseModal(id);
      return;
    }
    if (action === "delete-template-disease") {
      deleteTemplateDiseaseById(id);
      return;
    }
    if (action === "add-template-version") {
      if (id) {
        state.templateSelectedDiseaseId = id;
      }
      openAddTemplateVersionModal();
      return;
    }
    if (action === "edit-template-version") {
      const diseaseId = btn.dataset.diseaseId || btn.closest(".template-version-card")?.dataset.diseaseId;
      if (diseaseId) {
        state.templateSelectedDiseaseId = diseaseId;
      }
      openEditTemplateVersionModal(id);
      return;
    }
    if (action === "delete-template-version") {
      const diseaseId = btn.dataset.diseaseId || btn.closest(".template-version-card")?.dataset.diseaseId;
      if (diseaseId) {
        state.templateSelectedDiseaseId = diseaseId;
      }
      deleteTemplateVersionById(id);
      return;
    }
    if (action === "edit-template-item") {
      openEditTemplateItemModal(id);
      return;
    }
    if (action === "delete-template-item") {
      deleteTemplateItemById(id);
      return;
    }
    if (action === "edit-template-grade") {
      openEditTemplateGradeModal(id);
      return;
    }
    if (action === "delete-template-grade") {
      deleteTemplateGradeById(id);
      return;
    }
  }

  const versionCard = event.target.closest(".template-version-card[data-id]");
  if (versionCard) {
    const diseaseId = versionCard.dataset.diseaseId;
    if (diseaseId) {
      state.templateSelectedDiseaseId = diseaseId;
    }
    openTemplateConfigView(versionCard.dataset.id);
    return;
  }

  const diseaseCard = event.target.closest(".template-disease-card[data-id]");
  if (diseaseCard) {
    openTemplateVersionView(diseaseCard.dataset.id);
  }
}

function getTemplateFormFields(moduleKey, baseFields = []) {
  const schemaFields = (state.schemas[moduleKey] || []).filter((field) => !field.computed);
  const merged = [...baseFields];
  for (const field of schemaFields) {
    if (merged.some((item) => item.key === field.key)) continue;
    merged.push(field);
  }
  return merged.map((field) => ({
    ...field,
    readonly: !!field.readonly || !!field.locked
  }));
}

function collectTemplateValues(fields, values) {
  const payload = {};
  for (const field of fields) {
    payload[field.key] = String(values[field.key] ?? "").trim();
  }
  return payload;
}

function openAddTemplateDiseaseModal() {
  const fields = getTemplateFormFields("templateDisease", [
    { key: "diseaseName", label: "病种名称", type: "text", required: true }
  ]);

  openModal("新增病种模板", fields, {}, (values) => {
    const payload = collectTemplateValues(fields, values);
    const diseaseName = payload.diseaseName;
    if (!diseaseName) {
      alert("病种名称不能为空。");
      return false;
    }

    const row = {
      id: uid("tpld"),
      versions: [],
      ...payload
    };
    state.templates.unshift(row);
    state.templateSelectedDiseaseId = row.id;
    state.templateSelectedVersionId = "";
    state.templateExpandedDiseaseId = row.id;
    persistDataState();
    renderTemplateSection();
    showToast("病种模板已新增");
    return true;
  });
}

function openEditTemplateDiseaseModal(id) {
  const disease = state.templates.find((item) => item.id === id);
  if (!disease) return;

  const fields = getTemplateFormFields("templateDisease", [
    { key: "diseaseName", label: "病种名称", type: "text", required: true }
  ]);

  openModal("编辑病种模板", fields, disease, (values) => {
    const payload = collectTemplateValues(fields, values);
    const diseaseName = payload.diseaseName;
    if (!diseaseName) {
      alert("病种名称不能为空。");
      return false;
    }
    Object.assign(disease, payload);
    persistDataState();
    renderTemplateSection();
    showToast("病种模板已更新");
    return true;
  });
}

function deleteTemplateDiseaseById(id) {
  const disease = state.templates.find((item) => item.id === id);
  if (!disease) return;
  if (!confirm(`确认删除病种模板「${disease.diseaseName}」及其全部版本吗？`)) return;

  for (const version of (disease.versions || [])) {
    delete state.templateSimSelections[version.id];
  }
  state.templates = state.templates.filter((item) => item.id !== id);
  if (state.templateSelectedDiseaseId === id) {
    state.templateSelectedDiseaseId = "";
    state.templateSelectedVersionId = "";
  }
  if (state.templateExpandedDiseaseId === id) {
    state.templateExpandedDiseaseId = "";
  }
  normalizeTemplateSelection();
  persistDataState();
  renderTemplateSection();
  showToast("病种模板已删除");
}

function openAddTemplateVersionModal() {
  const disease = getSelectedTemplateDisease();
  if (!disease) {
    alert("\u8bf7\u5148\u9009\u62e9\u75c5\u79cd\u6a21\u677f\u3002");
    return;
  }
  const fields = getTemplateFormFields("templateVersion", [
    { key: "versionName", label: "\u7248\u672c\u540d\u79f0", type: "text", required: true }
  ]);

  openModal("\u65b0\u589e\u6d4b\u8bc4\u7248\u672c", fields, {}, (values) => {
    const payload = collectTemplateValues(fields, values);
    const versionName = payload.versionName;
    if (!versionName) {
      alert("\u7248\u672c\u540d\u79f0\u4e0d\u80fd\u4e3a\u7a7a\u3002");
      return false;
    }

    const row = {
      id: uid("tplv"),
      items: [],
      gradeRules: [],
      ...payload
    };
    disease.versions = disease.versions || [];
    disease.versions.unshift(row);
    state.templateSelectedVersionId = row.id;
    state.templateSimSelections[row.id] = {};
    state.templateExpandedDiseaseId = disease.id;
    persistDataState();
    renderTemplateSection();
    showToast("\u6d4b\u8bc4\u7248\u672c\u5df2\u65b0\u589e");
    return true;
  });
}

function openEditTemplateVersionModal(id) {
  const version = getSelectedTemplateDisease()?.versions?.find((item) => item.id === id);
  if (!version) return;

  const fields = getTemplateFormFields("templateVersion", [
    { key: "versionName", label: "\u7248\u672c\u540d\u79f0", type: "text", required: true }
  ]);

  openModal("\u7f16\u8f91\u6d4b\u8bc4\u7248\u672c", fields, version, (values) => {
    const payload = collectTemplateValues(fields, values);
    const versionName = payload.versionName;
    if (!versionName) {
      alert("\u7248\u672c\u540d\u79f0\u4e0d\u80fd\u4e3a\u7a7a\u3002");
      return false;
    }
    Object.assign(version, payload);
    persistDataState();
    renderTemplateSection();
    showToast("\u6d4b\u8bc4\u7248\u672c\u5df2\u66f4\u65b0");
    return true;
  });
}

function deleteTemplateVersionById(id) {
  const disease = getSelectedTemplateDisease();
  if (!disease) return;
  const version = disease.versions?.find((item) => item.id === id);
  if (!version) return;
  if (!confirm(`\u786e\u8ba4\u5220\u9664\u7248\u672c\u300c${version.versionName || "\u672a\u547d\u540d\u7248\u672c"}\u300d\u5417\uff1f`)) return;

  disease.versions = (disease.versions || []).filter((item) => item.id !== id);
  delete state.templateSimSelections[id];
  if (state.templateSelectedVersionId === id) {
    state.templateSelectedVersionId = "";
  }
  normalizeTemplateSelection();
  persistDataState();
  renderTemplateSection();
  showToast("\u6d4b\u8bc4\u7248\u672c\u5df2\u5220\u9664");
}

function openAddTemplateItemModal() {
  const version = getSelectedTemplateVersion();
  if (!version) {
    alert("请先选择版本。");
    return;
  }

  const fields = [
    { key: "name", label: "测评项名称", type: "text", required: true },
    { key: "options", label: "评分选项", type: "optionRows", required: true }
  ];
  openModal("新增测评项", fields, {}, (values) => {
    const name = (values.name || "").trim();
    if (!name) {
      alert("测评项名称不能为空。");
      return false;
    }

    const options = parseTemplateOptionRows(values.options || "");
    if (!options.ok) {
      alert(options.message);
      return false;
    }

    version.items = version.items || [];
    version.items.push({
      id: uid("tpli"),
      name,
      options: options.rows
    });
    persistDataState();
    renderTemplateSection();
    showToast("测评项已新增");
    return true;
  });
}

function openEditTemplateItemModal(id) {
  const version = getSelectedTemplateVersion();
  if (!version) return;
  const item = version.items?.find((row) => row.id === id);
  if (!item) return;

  const fields = [
    { key: "name", label: "测评项名称", type: "text", required: true },
    { key: "options", label: "评分选项", type: "optionRows", required: true }
  ];

  openModal("编辑测评项", fields, { ...item, options: item.options || [] }, (values) => {
    const name = (values.name || "").trim();
    if (!name) {
      alert("测评项名称不能为空。");
      return false;
    }
    const options = parseTemplateOptionRows(values.options || "");
    if (!options.ok) {
      alert(options.message);
      return false;
    }

    item.name = name;
    item.options = options.rows;
    const map = state.templateSimSelections[version.id] || {};
    if (map[item.id] && !item.options.some((opt) => opt.id === map[item.id])) {
      map[item.id] = "";
      state.templateSimSelections[version.id] = map;
    }
    persistDataState();
    renderTemplateSection();
    showToast("测评项已更新");
    return true;
  });
}

function deleteTemplateItemById(id) {
  const version = getSelectedTemplateVersion();
  if (!version) return;
  const item = version.items?.find((row) => row.id === id);
  if (!item) return;
  if (!confirm(`确认删除测评项「${item.name}」吗？`)) return;

  version.items = (version.items || []).filter((row) => row.id !== id);
  if (state.templateSimSelections[version.id]) {
    delete state.templateSimSelections[version.id][id];
  }
  persistDataState();
  renderTemplateSection();
  showToast("测评项已删除");
}

function openAddTemplateGradeModal() {
  const version = getSelectedTemplateVersion();
  if (!version) {
    alert("请先选择版本。");
    return;
  }
  const fields = [
    { key: "min", label: "最小分", type: "number", required: true },
    { key: "max", label: "最大分", type: "number", required: true },
    { key: "level", label: "患病等级", type: "text", required: true },
    { key: "note", label: "判定说明", type: "textarea", required: false }
  ];
  openModal("新增等级区间", fields, {}, (values) => {
    const parsed = parseGradeRuleInput(values);
    if (!parsed.ok) {
      alert(parsed.message);
      return false;
    }
    version.gradeRules = version.gradeRules || [];
    version.gradeRules.push({
      id: uid("tplg"),
      min: parsed.min,
      max: parsed.max,
      level: parsed.level,
      note: parsed.note
    });
    version.gradeRules.sort((a, b) => Number(a.min) - Number(b.min));
    persistDataState();
    renderTemplateSection();
    showToast("等级区间已新增");
    return true;
  });
}

function openEditTemplateGradeModal(id) {
  const version = getSelectedTemplateVersion();
  if (!version) return;
  const rule = version.gradeRules?.find((row) => row.id === id);
  if (!rule) return;
  const fields = [
    { key: "min", label: "最小分", type: "number", required: true },
    { key: "max", label: "最大分", type: "number", required: true },
    { key: "level", label: "患病等级", type: "text", required: true },
    { key: "note", label: "判定说明", type: "textarea", required: false }
  ];
  openModal("编辑等级区间", fields, rule, (values) => {
    const parsed = parseGradeRuleInput(values);
    if (!parsed.ok) {
      alert(parsed.message);
      return false;
    }
    rule.min = parsed.min;
    rule.max = parsed.max;
    rule.level = parsed.level;
    rule.note = parsed.note;
    version.gradeRules.sort((a, b) => Number(a.min) - Number(b.min));
    persistDataState();
    renderTemplateSection();
    showToast("等级区间已更新");
    return true;
  });
}

function deleteTemplateGradeById(id) {
  const version = getSelectedTemplateVersion();
  if (!version) return;
  const rule = version.gradeRules?.find((row) => row.id === id);
  if (!rule) return;
  if (!confirm(`确认删除等级区间「${rule.level}」吗？`)) return;

  version.gradeRules = (version.gradeRules || []).filter((row) => row.id !== id);
  persistDataState();
  renderTemplateSection();
  showToast("等级区间已删除");
}

function parseTemplateOptionLines(rawText) {
  const lines = String(rawText || "")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  if (!lines.length) {
    return { ok: false, message: "请至少填写一条评分选项。格式示例：轻度|1" };
  }

  const rows = [];
  for (const line of lines) {
    const match = line.match(/^(.+?)[|:：,，]\s*(-?\d+(?:\.\d+)?)$/);
    if (!match) {
      return { ok: false, message: `评分选项格式错误：${line}` };
    }
    const label = match[1].trim();
    const score = Number(match[2]);
    if (!label) {
      return { ok: false, message: "评分选项名称不能为空。" };
    }
    if (!Number.isFinite(score)) {
      return { ok: false, message: `评分选项分值非法：${line}` };
    }
    rows.push({ id: uid("tplo"), label, score });
  }
  return { ok: true, rows };
}

function parseTemplateOptionRows(rawValue) {
  if (Array.isArray(rawValue)) {
    return normalizeTemplateOptionRows(rawValue);
  }
  if (typeof rawValue === "string") {
    const trimmed = rawValue.trim();
    if (!trimmed) {
      return { ok: false, message: "请至少填写一条评分选项。" };
    }
    if (trimmed.startsWith("[")) {
      try {
        const parsed = JSON.parse(trimmed);
        return normalizeTemplateOptionRows(parsed);
      } catch {
        return { ok: false, message: "评分选项数据解析失败。" };
      }
    }
    if (trimmed.includes("|") || trimmed.includes(":") || trimmed.includes("：")) {
      return parseTemplateOptionLines(trimmed);
    }
  }
  return { ok: false, message: "请至少填写一条评分选项。" };
}

function normalizeTemplateOptionRows(rows) {
  if (!Array.isArray(rows)) {
    return { ok: false, message: "请至少填写一条评分选项。" };
  }
  const normalized = [];
  for (const row of rows) {
    const label = String(row?.label || "").trim();
    const score = Number(row?.score);
    if (!label) {
      return { ok: false, message: "评分选项名称不能为空。" };
    }
    if (!Number.isFinite(score)) {
      return { ok: false, message: `评分选项分值非法：${label}` };
    }
    normalized.push({ id: row?.id || uid("tplo"), label, score });
  }
  if (!normalized.length) {
    return { ok: false, message: "请至少填写一条评分选项。" };
  }
  return { ok: true, rows: normalized };
}

function parseGradeRuleInput(values) {
  const min = Number(values.min || 0);
  const max = Number(values.max || 0);
  const level = (values.level || "").trim();
  const note = (values.note || "").trim();
  if (!Number.isFinite(min) || !Number.isFinite(max)) {
    return { ok: false, message: "等级区间分值必须是数字。" };
  }
  if (min < 0 || max > 100) {
    return { ok: false, message: "等级区间建议在 0 到 100 分内。" };
  }
  if (min > max) {
    return { ok: false, message: "最小分不能大于最大分。" };
  }
  if (!level) {
    return { ok: false, message: "患病等级不能为空。" };
  }
  return { ok: true, min, max, level, note };
}

function normalizeTemplateSelection() {
  if (!Array.isArray(state.templates) || !state.templates.length) {
    state.templates = [];
    state.templateSelectedDiseaseId = "";
    state.templateSelectedVersionId = "";
    return;
  }

  const diseaseExists = state.templates.some((item) => item.id === state.templateSelectedDiseaseId);
  if (!diseaseExists) {
    state.templateSelectedDiseaseId = state.templates[0].id;
  }
  const expandedExists = state.templates.some((item) => item.id === state.templateExpandedDiseaseId);
  if (!expandedExists) {
    state.templateExpandedDiseaseId = "";
  }
  const disease = getSelectedTemplateDisease();
  disease.versions = Array.isArray(disease.versions) ? disease.versions : [];

  const versionExists = disease.versions.some((item) => item.id === state.templateSelectedVersionId);
  if (!versionExists) {
    state.templateSelectedVersionId = disease.versions[0]?.id || "";
  }

  const version = getSelectedTemplateVersion();
  if (version) {
    version.items = Array.isArray(version.items) ? version.items : [];
    version.gradeRules = Array.isArray(version.gradeRules) ? version.gradeRules : [];
    for (const item of version.items) {
      item.options = Array.isArray(item.options) ? item.options : [];
    }
  }
}

function getSelectedTemplateDisease() {
  return state.templates.find((item) => item.id === state.templateSelectedDiseaseId) || null;
}

function getSelectedTemplateVersion() {
  const disease = getSelectedTemplateDisease();
  if (!disease) return null;
  return (disease.versions || []).find((item) => item.id === state.templateSelectedVersionId) || null;
}

function renderFieldSection() {
  clearFieldSortVisuals();
  const moduleKey = el.schemaModuleSelect.value;
  const schema = state.schemas[moduleKey] || [];
  const visibleCount = schema.filter((field) => isFieldVisibleInList(moduleKey, field)).length;

  el.fieldStats.innerHTML = [
    statItem("当前模块", moduleLabel(moduleKey)),
    statItem("列表显示", `${visibleCount}/${schema.length || 0}`)
  ].join("");

  el.fieldSortModeBtn.classList.toggle("active", state.fieldsSortMode);
  el.fieldSortModeBtn.setAttribute("aria-pressed", String(state.fieldsSortMode));
  el.fieldSortModeBtn.textContent = state.fieldsSortMode ? "✓ 完成" : "↕ 调序";
  el.fieldSortModeBtn.title = state.fieldsSortMode ? "退出调整顺序模式" : "进入调整顺序模式";
  el.fieldList.classList.toggle("sort-mode", state.fieldsSortMode);

  el.fieldList.innerHTML = schema.length
    ? schema.map((field, index) => renderFieldCard(field, moduleKey, index, schema.length)).join("")
    : `<div class="empty">当前模块暂无字段</div>`;
}

function renderMineSection() {
  const enabled = isPasswordEnabled();
  const menuLabel = enabled ? "已开启" : "未开启";
  const inSubPage = !!state.mineSubPage;

  el.mineHomePane.classList.toggle("hidden", inSubPage);
  el.mineMigrationPane.classList.toggle("hidden", state.mineSubPage !== "migration");
  el.mineSecurityPane.classList.toggle("hidden", state.mineSubPage !== "security");
  el.mineFieldsPane.classList.toggle("hidden", state.mineSubPage !== "fields");

  el.mineSecurityMenuTag.textContent = menuLabel;
  el.mineSecurityMenuTag.classList.toggle("active", enabled);
  el.mineSecurityStatus.textContent = enabled ? "已开启" : "未开启";
  el.mineSecurityStatus.classList.toggle("active", enabled);
  el.mineSecurityHint.textContent = enabled
    ? "已开启应用密码保护，重启后需先输入密码。"
    : "开启后，应用每次启动都需要先输入密码。";
  el.mineSecurityActions.innerHTML = enabled
    ? `
      <button class="btn btn-light btn-small" type="button" data-action="change-password">修改密码</button>
      <button class="btn btn-light btn-small" type="button" data-action="disable-password">关闭密码</button>
    `
    : `
      <button class="btn btn-primary btn-small" type="button" data-action="enable-password">设置并开启密码</button>
    `;
}

function handleMineMenuNavigation(event) {
  const card = event.target.closest("[data-action='open-mine-submenu'][data-menu]");
  if (!card) return;
  openMineSubPage(card.dataset.menu);
}

function openMineSubPage(menuKey, silent = false) {
  const allowed = new Set(["migration", "security", "fields"]);
  if (!allowed.has(menuKey)) return;

  if (menuKey !== "fields" && state.fieldsSortMode) {
    state.fieldsSortMode = false;
    resetFieldSortState();
    clearFieldSortVisuals();
  }

  state.mineSubPage = menuKey;
  if (menuKey === "fields") {
    renderFieldSection();
  }
  renderMineSection();
  refreshPageHeader();
  refreshFabVisibility();
}

function closeMineSubPage(silent = false) {
  if (!state.mineSubPage) return;
  state.mineSubPage = "";
  if (state.fieldsSortMode) {
    state.fieldsSortMode = false;
    resetFieldSortState();
    clearFieldSortVisuals();
  }
  renderMineSection();
  refreshPageHeader();
  refreshFabVisibility();
  // no toast on back navigation
}

function handleMineActions(event) {
  const btn = event.target.closest("button[data-action]");
  if (!btn) return;

  const action = btn.dataset.action;
  if (action === "enable-password") {
    openSetPasswordModal();
    return;
  }
  if (action === "change-password") {
    openChangePasswordModal();
    return;
  }
  if (action === "disable-password") {
    openDisablePasswordModal();
  }
}

function openSetPasswordModal() {
  const fields = [
    { key: "newPassword", label: "设置密码", type: "password", required: true },
    { key: "confirmPassword", label: "确认密码", type: "password", required: true }
  ];

  openModal("开启访问密码", fields, {}, (values) => {
    const nextPassword = values.newPassword || "";
    if (nextPassword.length < 4) {
      alert("密码长度至少 4 位。");
      return false;
    }
    if (nextPassword !== values.confirmPassword) {
      alert("两次输入的密码不一致。");
      return false;
    }

    securityState.passwordEnabled = true;
    securityState.passwordValue = nextPassword;
    sessionUnlocked = true;
    persistSecurityState();
    renderMineSection();
    applyLockState();
    showToast("密码已开启，下次启动需验证");
    return true;
  });
}

function openChangePasswordModal() {
  if (!isPasswordEnabled()) {
    alert("请先开启密码保护。");
    return;
  }

  const fields = [
    { key: "oldPassword", label: "当前密码", type: "password", required: true },
    { key: "newPassword", label: "新密码", type: "password", required: true },
    { key: "confirmPassword", label: "确认新密码", type: "password", required: true }
  ];

  openModal("修改访问密码", fields, {}, (values) => {
    if ((values.oldPassword || "") !== securityState.passwordValue) {
      alert("当前密码不正确。");
      return false;
    }

    const nextPassword = values.newPassword || "";
    if (nextPassword.length < 4) {
      alert("新密码长度至少 4 位。");
      return false;
    }
    if (nextPassword !== values.confirmPassword) {
      alert("两次输入的新密码不一致。");
      return false;
    }

    securityState.passwordValue = nextPassword;
    persistSecurityState();
    showToast("密码已更新");
    return true;
  });
}

function openDisablePasswordModal() {
  if (!isPasswordEnabled()) return;

  const fields = [
    { key: "password", label: "确认当前密码", type: "password", required: true }
  ];
  openModal("关闭访问密码", fields, {}, (values) => {
    if ((values.password || "") !== securityState.passwordValue) {
      alert("密码不正确，无法关闭。");
      return false;
    }

    securityState.passwordEnabled = false;
    securityState.passwordValue = "";
    sessionUnlocked = true;
    persistSecurityState();
    renderMineSection();
    applyLockState();
    showToast("已关闭密码保护");
    return true;
  });
}

function exportDataFile() {
  const payload = {
    app: "hospital_record",
    version: 1,
    exportedAt: new Date().toISOString(),
    data: serializeDataState()
  };
  const content = JSON.stringify(payload, null, 2);
  const blob = new Blob([content], { type: "application/json;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const stamp = formatExportTime(new Date());
  const link = document.createElement("a");
  link.href = url;
  link.download = `hospital_record_backup_${stamp}.json`;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
  showToast("数据已导出");
}

async function handleImportDataFile(event) {
  const file = event.target.files?.[0];
  event.target.value = "";
  if (!file) return;

  if (!confirm("导入会覆盖当前本机数据，是否继续？")) {
    return;
  }

  try {
    const text = await file.text();
    const parsed = JSON.parse(text);
    const rawData = parsed && typeof parsed === "object" && parsed.data ? parsed.data : parsed;
    const normalized = normalizeImportedData(rawData);
    if (!normalized) {
      alert("导入文件格式不正确。");
      return;
    }

    applyImportedData(normalized);
    repairLegacyDataArtifacts();
    state.patientDetailNo = "";
    state.patientDetailAdmissionId = "";
    state.patientDetailDailyId = "";
    state.patientDetailAssessmentId = "";
    state.patientInHospitalOnly = false;
    state.fieldsSortMode = false;
    resetFieldSortState();
    clearFieldSortVisuals();
    persistDataState();
    renderAll();
    showToast("导入成功，数据已覆盖");
  } catch {
    alert("导入失败，请确认文件为有效 JSON 备份。");
  }
}

function tryUnlockApp() {
  if (!isPasswordEnabled()) {
    sessionUnlocked = true;
    applyLockState();
    return;
  }

  const input = String(el.appLockInput.value || "");
  if (input === securityState.passwordValue) {
    sessionUnlocked = true;
    applyLockState();
    showToast("解锁成功");
    return;
  }

  el.appLockError.classList.remove("hidden");
  el.appLockInput.select();
}

function applyLockState() {
  const needLock = isPasswordEnabled() && !sessionUnlocked;
  el.appLockOverlay.classList.toggle("hidden", !needLock);
  if (!needLock) {
    el.appLockError.classList.add("hidden");
    el.appLockInput.value = "";
    return;
  }

  el.appLockError.classList.add("hidden");
  el.appLockInput.value = "";
  setTimeout(() => el.appLockInput.focus(), 40);
}

function toggleFieldSortMode() {
  state.fieldsSortMode = !state.fieldsSortMode;
  if (!state.fieldsSortMode) {
    resetFieldSortState();
    clearFieldSortVisuals();
  }
  renderFieldSection();
}

function renderFieldCard(field, moduleKey, index, total) {
  const visible = isFieldVisibleInList(moduleKey, field);
  const fixedPrimary = moduleKey === "patient" && field.key === "admissionNo";
  const sortMode = state.fieldsSortMode;
  const canMoveUp = index > 0;
  const canMoveDown = index < total - 1;

  const inlineActions = `
    <div class="field-inline-actions">
      <button class="mini-btn edit" data-action="edit-field" data-key="${esc(field.key)}">编辑</button>
      <button class="mini-btn ghost" data-action="toggle-list-field" data-key="${esc(field.key)}" ${fixedPrimary ? "disabled" : ""}>
        ${visible ? "设为隐藏" : "设为显示"}
      </button>
      <button class="mini-btn delete" data-action="delete-field" data-key="${esc(field.key)}">删除</button>
    </div>
  `;

  return `
    <article class="entity-card field-card" data-field-key="${esc(field.key)}">
      <div class="entity-head field-card-head">
        <div class="entity-title">${esc(field.label)}</div>
        <div class="field-head-actions">
          ${sortMode ? `<span class="sort-order-tag">#${index + 1}</span>` : ""}
          <span class="entity-tag ${field.locked ? "active" : ""}">${field.locked ? "系统字段" : "可编辑"}</span>
          ${inlineActions}
        </div>
      </div>
      <div class="field-grid">
        ${fieldItem("类型", field.type)}
        ${fieldItem("必填", field.required ? "是" : "否")}
        ${fieldItem("列表显示", fixedPrimary ? "主键固定显示(右上角)" : (visible ? "是" : "否"))}
      </div>
      ${sortMode ? `
        <div class="card-actions field-sort-actions">
          <div class="sort-controls">
            <button class="mini-btn ghost sort-arrow" data-action="move-field-up" data-key="${esc(field.key)}" ${canMoveUp ? "" : "disabled"}>↑</button>
            <button class="mini-btn ghost sort-arrow" data-action="move-field-down" data-key="${esc(field.key)}" ${canMoveDown ? "" : "disabled"}>↓</button>
            <button class="drag-handle" type="button" data-action="start-sort" data-key="${esc(field.key)}" title="拖动调整次序" aria-label="拖动调整次序">≡</button>
          </div>
        </div>
      ` : ""}
    </article>
  `;
}

function handleFieldActions(event) {
  const btn = event.target.closest("button");
  if (!btn) return;

  const moduleKey = el.schemaModuleSelect.value;
  const action = btn.dataset.action;
  const key = btn.dataset.key;
  const field = state.schemas[moduleKey].find((item) => item.key === key);
  if (!field) return;

  if (action === "edit-field") {
    openEditFieldModal(moduleKey, field);
    return;
  }

  if (action === "move-field-up" || action === "move-field-down") {
    if (!state.fieldsSortMode) return;
    const step = action === "move-field-up" ? -1 : 1;
    const changed = moveFieldByStep(moduleKey, key, step);
    if (changed) {
      persistDataState();
      renderFieldSection();
      showToast(step < 0 ? "字段已上移" : "字段已下移");
    }
    return;
  }

  if (action === "toggle-list-field") {
    if (moduleKey === "patient" && key === "admissionNo") {
      alert("住院号作为主键固定显示在右上角，不参与列表字段切换。");
      return;
    }

    field.showInList = !isFieldVisibleInList(moduleKey, field);
    persistDataState();
    renderAll();
    showToast(`字段「${field.label}」已${field.showInList ? "显示" : "隐藏"}`);
    return;
  }

  if (action === "delete-field") {
    if (field.locked) {
      alert("系统字段不允许删除。");
      return;
    }
    if (!confirm(`确认删除字段「${field.label}」吗？`)) return;

    deleteField(moduleKey, key);
    persistDataState();
    renderAll();
    showToast("字段已删除并同步");
  }
}

function handleFieldSortPointerDown(event) {
  if (!state.fieldsSortMode) return;
  const handle = event.target.closest(".drag-handle");
  if (!handle) return;
  if (event.button !== undefined && event.button !== 0) return;

  const card = handle.closest(".field-card[data-field-key]");
  if (!card) return;

  fieldSortState.active = true;
  fieldSortState.pointerId = event.pointerId;
  fieldSortState.moduleKey = el.schemaModuleSelect.value;
  fieldSortState.dragKey = card.dataset.fieldKey;
  fieldSortState.dragCardEl = card;
  fieldSortState.overKey = card.dataset.fieldKey;
  fieldSortState.previewKey = "";
  fieldSortState.moved = false;
  fieldSortState.startX = event.clientX;
  fieldSortState.startY = event.clientY;
  fieldSortState.lastX = event.clientX;
  fieldSortState.lastY = event.clientY;
  fieldSortState.autoScrollSpeed = 0;
  card.style.setProperty("--drag-x", "0px");
  card.style.setProperty("--drag-y", "0px");

  clearFieldSortVisuals();
  el.fieldList.classList.add("sorting-active");
  card.classList.add("dragging");

  try {
    handle.setPointerCapture(event.pointerId);
  } catch {}

  event.preventDefault();
}

function handleFieldSortPointerMove(event) {
  if (!state.fieldsSortMode) return;
  if (!fieldSortState.active || event.pointerId !== fieldSortState.pointerId) return;

  const deltaX = Math.abs(event.clientX - fieldSortState.startX);
  const deltaY = Math.abs(event.clientY - fieldSortState.startY);
  if (!fieldSortState.moved && deltaX + deltaY < 8) return;
  fieldSortState.moved = true;
  fieldSortState.lastX = event.clientX;
  fieldSortState.lastY = event.clientY;
  if (fieldSortState.dragCardEl) {
    const offsetX = event.clientX - fieldSortState.startX;
    const offsetY = event.clientY - fieldSortState.startY;
    fieldSortState.dragCardEl.style.setProperty("--drag-x", `${offsetX}px`);
    fieldSortState.dragCardEl.style.setProperty("--drag-y", `${offsetY}px`);
  }

  updateFieldSortTargetAt(event.clientX, event.clientY);
  updateFieldSortAutoScroll(event.clientY);
}

function handleFieldSortPointerUp(event) {
  if (!fieldSortState.active || event.pointerId !== fieldSortState.pointerId) return;
  stopFieldSortAutoScroll();

  const { moduleKey, dragKey, overKey, moved } = fieldSortState;
  const needSort = moved && overKey && dragKey && overKey !== dragKey;
  if (needSort) {
    const changed = reorderFieldSchema(moduleKey, dragKey, overKey);
    if (changed) {
      persistDataState();
      renderFieldSection();
      showToast("字段次序已调整");
    }
  }

  resetFieldSortState();
  clearFieldSortVisuals();
}

function handleFieldSortPointerCancel() {
  if (!fieldSortState.active) return;
  stopFieldSortAutoScroll();
  resetFieldSortState();
  clearFieldSortVisuals();
}

function updateFieldSortTargetAt(clientX, clientY) {
  const elAtPoint = document.elementFromPoint(clientX, clientY);
  const overCard = elAtPoint?.closest(".field-card[data-field-key]");
  if (!overCard) {
    fieldSortState.overKey = "";
    setFieldDropTarget("");
    return;
  }

  const overKey = overCard.dataset.fieldKey;
  fieldSortState.overKey = overKey;
  setFieldDropTarget(overKey !== fieldSortState.dragKey ? overKey : "");
}

function updateFieldSortAutoScroll(clientY) {
  const rect = el.pageHost.getBoundingClientRect();
  const threshold = 72;
  let speed = 0;

  if (clientY < rect.top + threshold) {
    speed = -Math.ceil((rect.top + threshold - clientY) / 6);
  } else if (clientY > rect.bottom - threshold) {
    speed = Math.ceil((clientY - (rect.bottom - threshold)) / 6);
  }

  speed = Math.max(-16, Math.min(16, speed));
  fieldSortState.autoScrollSpeed = speed;

  if (speed !== 0 && !fieldSortState.autoScrollRaf) {
    fieldSortState.autoScrollRaf = requestAnimationFrame(stepFieldSortAutoScroll);
  }
  if (speed === 0) {
    stopFieldSortAutoScroll();
  }
}

function stepFieldSortAutoScroll() {
  if (!fieldSortState.active || fieldSortState.autoScrollSpeed === 0) {
    stopFieldSortAutoScroll();
    return;
  }

  el.pageHost.scrollTop += fieldSortState.autoScrollSpeed;
  updateFieldSortTargetAt(fieldSortState.lastX, fieldSortState.lastY);
  fieldSortState.autoScrollRaf = requestAnimationFrame(stepFieldSortAutoScroll);
}

function stopFieldSortAutoScroll() {
  if (fieldSortState.autoScrollRaf) {
    cancelAnimationFrame(fieldSortState.autoScrollRaf);
    fieldSortState.autoScrollRaf = 0;
  }
}

function setFieldDropTarget(key) {
  if (fieldSortState.previewKey === key) return;
  fieldSortState.previewKey = key;

  el.fieldList.querySelectorAll(".field-card.drop-target").forEach((card) => {
    card.classList.remove("drop-target");
  });
  if (key) {
    const target = Array.from(el.fieldList.querySelectorAll(".field-card[data-field-key]"))
      .find((card) => card.dataset.fieldKey === key);
    if (target) {
      target.classList.add("drop-target");
    }
  }

  applyFieldSortPreviewTransforms(fieldSortState.moduleKey, fieldSortState.dragKey, key);
}

function applyFieldSortPreviewTransforms(moduleKey, dragKey, overKey) {
  clearFieldSortPreviewTransforms();
  if (!moduleKey || !dragKey || !overKey || dragKey === overKey) return;

  const schema = state.schemas[moduleKey];
  if (!Array.isArray(schema)) return;

  const fromIndex = schema.findIndex((item) => item.key === dragKey);
  const toIndex = schema.findIndex((item) => item.key === overKey);
  if (fromIndex < 0 || toIndex < 0 || fromIndex === toIndex) return;

  const cards = Array.from(el.fieldList.querySelectorAll(".field-card[data-field-key]"));
  const dragCard = cards.find((card) => card.dataset.fieldKey === dragKey);
  if (!dragCard) return;

  const listStyle = getComputedStyle(el.fieldList);
  const gap = parseFloat(listStyle.rowGap || listStyle.gap || "10") || 10;
  const shift = dragCard.getBoundingClientRect().height + gap;

  if (fromIndex < toIndex) {
    for (let i = fromIndex + 1; i <= toIndex; i += 1) {
      const card = cards[i];
      if (!card) continue;
      card.classList.add("sort-preview");
      card.style.transform = `translateY(${-shift}px)`;
    }
  } else {
    for (let i = toIndex; i < fromIndex; i += 1) {
      const card = cards[i];
      if (!card) continue;
      card.classList.add("sort-preview");
      card.style.transform = `translateY(${shift}px)`;
    }
  }
}

function clearFieldSortPreviewTransforms() {
  el.fieldList.querySelectorAll(".field-card.sort-preview").forEach((card) => {
    card.classList.remove("sort-preview");
    card.style.transform = "";
  });
}

function reorderFieldSchema(moduleKey, dragKey, overKey) {
  const schema = state.schemas[moduleKey];
  if (!Array.isArray(schema)) return false;

  const fromIndex = schema.findIndex((item) => item.key === dragKey);
  const toIndex = schema.findIndex((item) => item.key === overKey);
  if (fromIndex < 0 || toIndex < 0 || fromIndex === toIndex) return false;

  const [movedItem] = schema.splice(fromIndex, 1);
  schema.splice(toIndex, 0, movedItem);
  return true;
}

function moveFieldByStep(moduleKey, key, step) {
  const schema = state.schemas[moduleKey];
  if (!Array.isArray(schema)) return false;

  const from = schema.findIndex((item) => item.key === key);
  if (from < 0) return false;
  const to = from + step;
  if (to < 0 || to >= schema.length) return false;

  const [item] = schema.splice(from, 1);
  schema.splice(to, 0, item);
  return true;
}

function resetFieldSortState() {
  stopFieldSortAutoScroll();
  fieldSortState.active = false;
  fieldSortState.pointerId = null;
  fieldSortState.moduleKey = "";
  fieldSortState.dragKey = "";
  fieldSortState.dragCardEl = null;
  fieldSortState.overKey = "";
  fieldSortState.previewKey = "";
  fieldSortState.moved = false;
  fieldSortState.startX = 0;
  fieldSortState.startY = 0;
  fieldSortState.lastX = 0;
  fieldSortState.lastY = 0;
  fieldSortState.autoScrollSpeed = 0;
}

function clearFieldSortVisuals() {
  clearFieldSortPreviewTransforms();
  fieldSortState.previewKey = "";
  el.fieldList.classList.remove("sorting-active");
  el.fieldList.querySelectorAll(".field-card.dragging, .field-card.drop-target").forEach((card) => {
    card.classList.remove("dragging", "drop-target");
    card.style.removeProperty("--drag-x");
    card.style.removeProperty("--drag-y");
  });
}

function openAddPatientModal() {
  openPatientModal("新增病人信息", {}, false);
}

function openPatientModal(title, currentData, isEdit) {
  const fields = state.schemas.patient.map((field) => ({
    ...field,
    readonly: isEdit && field.key === "admissionNo"
  }));

  openModal(title, fields, currentData, (values) => {
    const payload = applySchemaCoercion(values, state.schemas.patient);
    const admissionNo = (values.admissionNo || "").trim();
    if (!admissionNo) {
      alert("住院号不能为空");
      return false;
    }

    const exists = state.patients.some((item) => item.admissionNo === admissionNo);
    if (!isEdit && exists) {
      alert("住院号已存在，请使用唯一住院号。");
      return false;
    }

    if (isEdit) {
      state.patients = state.patients.map((item) =>
        item.admissionNo === currentData.admissionNo ? { ...item, ...payload } : item
      );
    } else {
      state.patients.unshift(payload);
      state.selectedPatientNo = admissionNo;
    }

    persistDataState();
    renderAll();
    showToast(isEdit ? "病人信息已更新" : "病人已新增");
    return true;
  });
}

function openAddAdmissionModal() {
  if (!state.selectedPatientNo) {
    alert("请先新增病人信息。");
    return;
  }
  if (hasInHospitalAdmission(state.selectedPatientNo)) {
    alert("该病人当前有在院记录，暂不可新增入院记录。");
    return;
  }
  openAdmissionModal("新增入院记录", {}, false);
}

function openAddAdmissionFromPatientDetail() {
  if (!state.patientDetailNo) return;
  if (hasInHospitalAdmission(state.patientDetailNo)) {
    alert("该病人当前有在院记录，暂不可新增入院记录。");
    return;
  }
  state.selectedPatientNo = state.patientDetailNo;
  state.patientDetailAdmissionId = "";
  state.patientDetailDailyId = "";
  state.patientDetailAssessmentId = "";
  state.patientDetailImagingPreviewId = "";
  state.admissionImagingPickerOpen = false;
  syncAdmissionImagingSourceRow();
  openAddAdmissionModal();
}

function openAddDailyFromPatientDetail() {
  if (!state.patientDetailAdmissionId) return;
  state.selectedAdmissionId = state.patientDetailAdmissionId;
  openAddDailyModal();
}

function openAdmissionModal(title, currentData, isEdit) {
  const fields = [
    { key: "admissionNo", label: "住院号", type: "text", required: true, readonly: true },
    ...state.schemas.admission
  ];

  openModal(title, fields, { ...currentData, admissionNo: state.selectedPatientNo }, (values) => {
    const payload = applySchemaCoercion(values, state.schemas.admission);
    payload.admissionNo = state.selectedPatientNo;

    if (isEdit) {
      state.admissions = state.admissions.map((item) =>
        item._id === currentData._id ? { ...item, ...payload } : item
      );
    } else {
      const row = { _id: uid("adm"), ...payload };
      state.admissions.unshift(row);
      state.selectedAdmissionId = row._id;
    }

    persistDataState();
    renderAdmissionSection();
    if (state.patientDetailNo) renderPatientSection();
    showToast(isEdit ? "入院记录已更新" : "入院记录已新增");
    return true;
  });
}

function openAddDailyModal() {
  if (!state.selectedAdmissionId) {
    alert("请先选择一条入院记录。");
    return;
  }
  openDailyModal("新增日常记录", {}, false);
}

function openDailyModal(title, currentData, isEdit) {
  openModal(title, state.schemas.daily, currentData, (values) => {
    const payload = applySchemaCoercion(values, state.schemas.daily);
    if (isEdit) {
      state.dailyRecords = state.dailyRecords.map((item) =>
        item._id === currentData._id ? { ...item, ...payload } : item
      );
    } else {
      state.dailyRecords.unshift({
        _id: uid("daily"),
        admissionId: state.selectedAdmissionId,
        ...payload
      });
    }

    persistDataState();
    renderAdmissionSection();
    if (state.patientDetailNo) renderPatientSection();
    showToast(isEdit ? "日常记录已更新" : "日常记录已新增");
    return true;
  });
}

function openAddFieldModal() {
  const moduleKey = el.schemaModuleSelect.value;
  const fields = [
    { key: "key", label: "字段键名", type: "text", required: true },
    { key: "label", label: "字段名称", type: "text", required: true },
    { key: "type", label: "字段类型", type: "select", options: ["text", "number", "date", "textarea", "select", "images"], required: true },
    { key: "required", label: "是否必填", type: "select", options: ["true", "false"], required: true },
    { key: "showInList", label: "是否在列表显示", type: "select", options: ["true", "false"], required: true },
    { key: "options", label: "下拉选项(逗号分隔，仅select类型)", type: "text", required: false }
  ];

  openModal("新增字段", fields, { required: "false", type: "text", showInList: "true" }, (values) => {
    const newKey = (values.key || "").trim();
    if (!/^[a-zA-Z][a-zA-Z0-9_]*$/.test(newKey)) {
      alert("字段键名需为英文字母开头，可包含数字和下划线。");
      return false;
    }

    if (state.schemas[moduleKey].some((item) => item.key === newKey)) {
      alert("字段键名已存在，请更换。");
      return false;
    }

    const newField = {
      key: newKey,
      label: (values.label || "").trim(),
      type: values.type,
      required: values.required === "true",
      showInList: values.showInList === "true"
    };

    if (values.type === "select") {
      const opts = (values.options || "").split(",").map((s) => s.trim()).filter(Boolean);
      if (!opts.length) {
        alert("select 类型必须提供下拉选项。");
        return false;
      }
      newField.options = opts;
    }

    state.schemas[moduleKey].push(newField);
    backfillField(moduleKey, newField.key, "");

    persistDataState();
    renderAll();
    showToast("字段新增成功，已同步业务模块");
    return true;
  });
}

function openEditFieldModal(moduleKey, field) {
  const mandatoryRequired = isCoreRequiredField(moduleKey, field.key);
  const fields = [
    { key: "key", label: "字段键名", type: "text", required: true, readonly: true },
    { key: "label", label: "字段名称", type: "text", required: true },
    { key: "type", label: "字段类型", type: "select", options: ["text", "number", "date", "textarea", "select", "images"], required: true, readonly: true },
    { key: "required", label: "是否必填", type: "select", options: ["true", "false"], required: true, readonly: mandatoryRequired },
    { key: "showInList", label: "是否在列表显示", type: "select", options: ["true", "false"], required: true, readonly: moduleKey === "patient" && field.key === "admissionNo" },
    { key: "options", label: "下拉选项(逗号分隔，仅select类型)", type: "text", required: false }
  ];

  openModal(
    `编辑字段 - ${field.label}`,
    fields,
    {
      key: field.key,
      label: field.label,
      type: field.type,
      required: String(!!field.required),
      showInList: String(isFieldVisibleInList(moduleKey, field)),
      options: (field.options || []).join(",")
    },
    (values) => {
      const nextKey = (values.key || "").trim();
      if (nextKey !== field.key) {
        alert("字段键名创建后不可修改。");
        return false;
      }

      const schema = state.schemas[moduleKey];
      const target = schema.find((item) => item.key === field.key);
      if (!target) return false;

      target.key = field.key;
      target.label = (values.label || "").trim();
      if (values.type !== field.type) {
        alert("字段类型创建后不可修改。");
        return false;
      }
      target.type = field.type;
      target.required = values.required === "true";
      target.showInList = values.showInList === "true";

      if (isCoreRequiredField(moduleKey, target.key)) {
        target.required = true;
      }

      if (moduleKey === "patient" && target.key === "admissionNo") {
        target.showInList = false;
        target.locked = true;
      }

      if (moduleKey === "admission" && target.key === "admitDate") {
        target.locked = true;
      }

      if (field.type === "select") {
        const opts = (values.options || "").split(",").map((s) => s.trim()).filter(Boolean);
        target.options = opts.length ? opts : ["选项1"];
      } else {
        delete target.options;
      }

      persistDataState();
      renderAll();
      showToast("字段已更新并同步");
      return true;
    }
  );
}

function deleteField(moduleKey, key) {
  if (isCoreRequiredField(moduleKey, key)) return;
  state.schemas[moduleKey] = state.schemas[moduleKey].filter((item) => item.key !== key);
  if (moduleKey === "patient") state.patients.forEach((item) => delete item[key]);
  if (moduleKey === "admission") state.admissions.forEach((item) => delete item[key]);
  if (moduleKey === "daily") state.dailyRecords.forEach((item) => delete item[key]);
  if (moduleKey === "templateDisease") {
    state.templates.forEach((item) => delete item[key]);
  }
  if (moduleKey === "templateVersion") {
    state.templates.forEach((disease) => {
      (disease.versions || []).forEach((version) => delete version[key]);
    });
  }
}

function backfillField(moduleKey, key, defaultValue) {
  if (moduleKey === "patient") {
    state.patients = state.patients.map((item) => ({ ...item, [key]: defaultValue }));
  }
  if (moduleKey === "admission") {
    state.admissions = state.admissions.map((item) => ({ ...item, [key]: defaultValue }));
  }
  if (moduleKey === "daily") {
    state.dailyRecords = state.dailyRecords.map((item) => ({ ...item, [key]: defaultValue }));
  }
  if (moduleKey === "templateDisease") {
    state.templates = state.templates.map((item) => ({ ...item, [key]: defaultValue }));
  }
  if (moduleKey === "templateVersion") {
    state.templates = state.templates.map((disease) => ({
      ...disease,
      versions: (disease.versions || []).map((version) => ({ ...version, [key]: defaultValue }))
    }));
  }
}

function renameField(moduleKey, oldKey, newKey) {
  const remap = (row) => {
    if (!(oldKey in row)) return row;
    row[newKey] = row[oldKey];
    delete row[oldKey];
    return row;
  };

  if (moduleKey === "patient") state.patients = state.patients.map(remap);
  if (moduleKey === "admission") state.admissions = state.admissions.map(remap);
  if (moduleKey === "daily") state.dailyRecords = state.dailyRecords.map(remap);
  if (moduleKey === "templateDisease") state.templates = state.templates.map(remap);
  if (moduleKey === "templateVersion") {
    state.templates = state.templates.map((disease) => ({
      ...disease,
      versions: (disease.versions || []).map(remap)
    }));
  }
}

function hydrateFromStorage() {
  try {
    const rawData = localStorage.getItem(STORAGE_DATA_KEY);
    if (rawData) {
      const parsed = JSON.parse(rawData);
      const candidate = parsed && typeof parsed === "object" && parsed.data ? parsed.data : parsed;
      const normalized = normalizeImportedData(candidate);
      if (normalized) {
        applyImportedData(normalized);
      }
    }
  } catch {}

  try {
    const rawSecurity = localStorage.getItem(STORAGE_SECURITY_KEY);
    if (rawSecurity) {
      const parsed = JSON.parse(rawSecurity);
      if (parsed && typeof parsed === "object") {
        securityState.passwordEnabled = !!parsed.passwordEnabled;
        securityState.passwordValue = typeof parsed.passwordValue === "string" ? parsed.passwordValue : "";
      }
    }
  } catch {}

  if (!securityState.passwordValue) {
    securityState.passwordEnabled = false;
  }
}

function normalizeSelectionState() {
  normalizeTemplateSelection();
  if (!state.patients.length) {
    state.selectedPatientNo = "";
    state.selectedAdmissionId = "";
    return;
  }

  const hasSelectedPatient = state.patients.some((item) => item.admissionNo === state.selectedPatientNo);
  if (!hasSelectedPatient) {
    state.selectedPatientNo = state.patients[0].admissionNo;
  }

  const selectedAdmissions = state.admissions.filter((item) => item.admissionNo === state.selectedPatientNo);
  const hasSelectedAdmission = selectedAdmissions.some((item) => item._id === state.selectedAdmissionId);
  if (!hasSelectedAdmission) {
    state.selectedAdmissionId = selectedAdmissions[0]?._id || "";
  }
}

function serializeDataState() {
  return {
    schemas: JSON.parse(JSON.stringify(state.schemas)),
    patients: JSON.parse(JSON.stringify(state.patients)),
    admissions: JSON.parse(JSON.stringify(state.admissions)),
    dailyRecords: JSON.parse(JSON.stringify(state.dailyRecords)),
    templates: JSON.parse(JSON.stringify(state.templates || [])),
    admissionAssessments: JSON.parse(JSON.stringify(state.admissionAssessments || {})),
    admissionImaging: JSON.parse(JSON.stringify(state.admissionImaging || {}))
  };
}

function normalizeImportedData(raw) {
  if (!raw || typeof raw !== "object") return null;
  if (!raw.schemas || typeof raw.schemas !== "object") return null;
  if (!Array.isArray(raw.schemas.patient) || !Array.isArray(raw.schemas.admission) || !Array.isArray(raw.schemas.daily)) {
    return null;
  }
  if (!Array.isArray(raw.patients) || !Array.isArray(raw.admissions) || !Array.isArray(raw.dailyRecords)) {
    return null;
  }

  const admissions = raw.admissions.map((item) => ({
    ...(item || {}),
    _id: item?._id || uid("adm")
  }));
  const admissionIdSet = new Set(admissions.map((item) => item._id));
  const dailyRecords = raw.dailyRecords
    .map((item) => ({
      ...(item || {}),
      _id: item?._id || uid("daily")
    }))
    .filter((item) => admissionIdSet.has(item.admissionId));

  const templatesRaw = Array.isArray(raw.templates) ? raw.templates : (state.templates || []);
  const templates = templatesRaw.map((disease) => ({
    ...(disease || {}),
    id: disease?.id || uid("tpld"),
    diseaseName: String(disease?.diseaseName || "").trim(),
    diseaseCode: String(disease?.diseaseCode || "").trim(),
    description: String(disease?.description || "").trim(),
    versions: Array.isArray(disease?.versions)
      ? disease.versions.map((version) => ({
        ...(version || {}),
        id: version?.id || uid("tplv"),
        versionName: String(version?.versionName || "").trim(),
        year: String(version?.year || "").trim(),
        description: String(version?.description || "").trim(),
        items: Array.isArray(version?.items)
          ? version.items.map((item) => ({
            id: item?.id || uid("tpli"),
            name: String(item?.name || "").trim(),
            options: Array.isArray(item?.options)
              ? item.options.map((opt) => ({
                id: opt?.id || uid("tplo"),
                label: String(opt?.label || "").trim(),
                score: Number(opt?.score || 0)
              }))
              : []
          }))
          : [],
        gradeRules: Array.isArray(version?.gradeRules)
          ? version.gradeRules.map((rule) => ({
            id: rule?.id || uid("tplg"),
            min: Number(rule?.min || 0),
            max: Number(rule?.max || 0),
            level: String(rule?.level || "").trim(),
            note: String(rule?.note || "").trim()
          }))
          : []
      }))
      : []
  }));

  const admissionAssessments = raw.admissionAssessments && typeof raw.admissionAssessments === "object"
    ? raw.admissionAssessments
    : {};
  const admissionImagingRaw = raw.admissionImaging && typeof raw.admissionImaging === "object"
    ? raw.admissionImaging
    : {};
  const admissionImaging = {};
  Object.keys(admissionImagingRaw).forEach((admissionId) => {
    if (!admissionIdSet.has(admissionId)) return;
    admissionImaging[admissionId] = normalizeImageItems(admissionImagingRaw[admissionId]);
  });

  return {
    schemas: JSON.parse(JSON.stringify(raw.schemas)),
    patients: raw.patients.map((item) => ({ ...(item || {}) })),
    admissions,
    dailyRecords,
    templates,
    admissionAssessments,
    admissionImaging
  };
}

function applyImportedData(nextData) {
  state.schemas = nextData.schemas;
  state.patients = nextData.patients;
  state.admissions = nextData.admissions;
  state.dailyRecords = nextData.dailyRecords;
  state.templates = Array.isArray(nextData.templates) ? nextData.templates : [];
  state.admissionAssessments = nextData.admissionAssessments && typeof nextData.admissionAssessments === "object"
    ? nextData.admissionAssessments
    : {};
  state.admissionImaging = nextData.admissionImaging && typeof nextData.admissionImaging === "object"
    ? nextData.admissionImaging
    : {};
  state.patientDetailImagingPreviewId = "";
  state.admissionImagingPickerOpen = false;
  state.templateView = "disease";
  state.templateSelectedDiseaseId = "";
  state.templateSelectedVersionId = "";
  state.templateExpandedDiseaseId = "";
  state.templateSimSelections = {};
  repairLegacyDataArtifacts();
  enforceCoreFieldRules();
  normalizeSelectionState();
}

function persistDataState() {
  try {
    localStorage.setItem(STORAGE_DATA_KEY, JSON.stringify(serializeDataState()));
  } catch {}
}

function persistSecurityState() {
  try {
    localStorage.setItem(STORAGE_SECURITY_KEY, JSON.stringify({
      passwordEnabled: !!securityState.passwordEnabled,
      passwordValue: securityState.passwordValue || ""
    }));
  } catch {}
}

function isPasswordEnabled() {
  return !!securityState.passwordEnabled && !!securityState.passwordValue;
}

function formatExportTime(date) {
  const pad = (num) => String(num).padStart(2, "0");
  return `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}_${pad(date.getHours())}${pad(date.getMinutes())}${pad(date.getSeconds())}`;
}

function openModal(title, fields, values, onSubmit) {
  modalState.onSubmit = onSubmit;
  el.modalTitle.textContent = title;
  if (el.modalSubtitle) {
    el.modalSubtitle.textContent = getModalSubtitle(title);
  }
  el.modalForm.innerHTML = fields.map((field) => renderFormItem(field, values[field.key])).join("");
  el.modalOverlay.classList.remove("hidden");
}

function closeModal() {
  el.modalOverlay.classList.add("hidden");
  el.modalForm.innerHTML = "";
  if (el.modalShell) {
    el.modalShell.classList.remove("assessment-modal");
  }
  assessmentDraft = null;
  assessmentDraftMode = "create";
  assessmentDraftSourceId = "";
  modalState.onSubmit = null;
}

function submitModal() {
  if (!modalState.onSubmit) return;

  const payload = {};
  const nodes = el.modalForm.querySelectorAll("[data-field]");
  for (const node of nodes) {
    payload[node.dataset.field] = String(node.value || "").trim();
  }

  el.modalForm.querySelectorAll(".option-rows[data-field]").forEach((container) => {
    syncOptionRowsValue(container);
    const fieldKey = container.dataset.field;
    const hidden = container.closest(".form-item")?.querySelector(`input[type="hidden"][data-field="${fieldKey}"]`);
    if (hidden) {
      payload[fieldKey] = String(hidden.value || "").trim();
    }
  });

  const wrappers = el.modalForm.querySelectorAll(".form-item");
  for (const node of wrappers) {
    const required = node.dataset.required === "true";
    if (!required) continue;
    const key = node.dataset.key;
    if (node.dataset.type === "images") {
      const images = normalizeImageItems(payload[key] || "");
      if (!images.length) {
        alert(`请上传「${node.dataset.label}」`);
        return;
      }
      continue;
    }
    if (!payload[key]) {
      alert(`请填写「${node.dataset.label}」`);
      return;
    }
  }

  const ok = modalState.onSubmit(payload);
  if (ok) closeModal();
}

function getModalSubtitle(title) {
  if (title.includes("编辑")) return "建议核对关键字段后保存，更新将实时同步到对应模块。";
  if (title.includes("新增")) return "请完整填写必填项，保存后可在当前页面立即查看结果。";
  return "请完善信息后保存，改动会即时生效。";
}

function renderFormItem(field, value) {
  const val = readValue(value);
  const common = `data-field="${esc(field.key)}" ${field.readonly ? "disabled" : ""}`;
  const label = esc(field.label);

  if (field.type === "optionRows") {
    let rows = [];
    if (Array.isArray(value)) {
      rows = value;
    } else if (typeof value === "string" && value.trim()) {
      try {
        rows = JSON.parse(value);
      } catch {
        rows = [];
      }
    }
    if (!rows.length) {
      rows = [{ id: uid("tplo"), label: "", score: "" }];
    }
    const rowsHtml = rows.map((row) => renderOptionRow(row)).join("");
    const jsonValue = esc(JSON.stringify(rows));
    return `
      <div class="form-item option-rows-item" data-required="${field.required ? "true" : "false"}" data-key="${esc(field.key)}" data-label="${esc(field.label)}">
        <label>${label}</label>
        <div class="option-rows" data-field="${esc(field.key)}">${rowsHtml}</div>
        <div class="option-row-actions">
          <button class="mini-btn" type="button" data-action="add-option-row" data-field="${esc(field.key)}">新增选项</button>
        </div>
        <input type="hidden" value="${jsonValue}" ${common}>
      </div>
    `;
  }

  if (field.type === "images") {
    const items = normalizeImageItems(value);
    const gridHtml = items.length ? items.map((item) => renderImageThumb(item)).join("") : "";
    const jsonValue = esc(JSON.stringify(items));
    return `
      <div class="form-item image-field" data-type="images" data-required="${field.required ? "true" : "false"}" data-key="${esc(field.key)}" data-label="${esc(field.label)}">
        <label>${label}</label>
        <div class="image-grid" data-field="${esc(field.key)}">${gridHtml}</div>
        <div class="image-actions">
          <button class="mini-btn" type="button" data-action="add-image-camera" data-field="${esc(field.key)}">拍照</button>
          <button class="mini-btn ghost" type="button" data-action="add-image-album" data-field="${esc(field.key)}">相册</button>
        </div>
        <input class="hidden-file-input" type="file" accept="image/*" capture="environment" data-action="image-camera-input" data-field="${esc(field.key)}">
        <input class="hidden-file-input" type="file" accept="image/*" multiple data-action="image-album-input" data-field="${esc(field.key)}">
        <input type="hidden" value="${jsonValue}" ${common}>
      </div>
    `;
  }

  if (field.type === "textarea") {
    return `
      <div class="form-item" data-required="${field.required ? "true" : "false"}" data-key="${esc(field.key)}" data-label="${esc(field.label)}">
        <label>${label}</label>
        <textarea rows="4" ${common}>${esc(val)}</textarea>
      </div>
    `;
  }

  if (field.type === "select") {
    const options = (field.options || []).map((item) => {
      const selected = item === val ? "selected" : "";
      return `<option value="${esc(item)}" ${selected}>${esc(item)}</option>`;
    }).join("");

    return `
      <div class="form-item" data-required="${field.required ? "true" : "false"}" data-key="${esc(field.key)}" data-label="${esc(field.label)}">
        <label>${label}</label>
        <select ${common}>${options}</select>
      </div>
    `;
  }

  const inputType = field.type === "number"
    ? "number"
    : field.type === "date"
      ? "date"
      : field.type === "password"
        ? "password"
        : "text";
  return `
    <div class="form-item" data-required="${field.required ? "true" : "false"}" data-key="${esc(field.key)}" data-label="${esc(field.label)}">
      <label>${label}</label>
      <input type="${inputType}" value="${esc(val)}" ${common}>
    </div>
  `;
}

function handleModalFormActions(event) {
  const btn = event.target.closest("button[data-action]");
  if (!btn) return;
  const action = btn.dataset.action;
  if (action === "add-option-row") {
    const fieldKey = btn.dataset.field;
    const container = el.modalForm.querySelector(`.option-rows[data-field="${fieldKey}"]`);
    if (!container) return;
    container.insertAdjacentHTML("beforeend", renderOptionRow({}));
    syncOptionRowsValue(container);
    return;
  }
  if (action === "remove-option-row") {
    const row = btn.closest(".option-row");
    const container = btn.closest(".option-rows");
    if (!row || !container) return;
    row.remove();
    if (!container.querySelector(".option-row")) {
      container.insertAdjacentHTML("beforeend", renderOptionRow({}));
    }
    syncOptionRowsValue(container);
    return;
  }
  if (action === "add-image-camera" || action === "add-image-album") {
    const fieldKey = btn.dataset.field;
    if (!fieldKey) return;
    const selector = action === "add-image-camera" ? "[data-action='image-camera-input']" : "[data-action='image-album-input']";
    const input = el.modalForm.querySelector(`input[type="file"][data-field="${fieldKey}"]${selector}`);
    if (input) input.click();
    return;
  }
  if (action === "remove-image") {
    const thumb = btn.closest(".image-thumb");
    const grid = btn.closest(".image-grid");
    if (!thumb || !grid) return;
    thumb.remove();
    syncImageFieldValue(grid);
  }
}

function handleModalFormInput(event) {
  const container = event.target.closest(".option-rows");
  if (!container) return;
  syncOptionRowsValue(container);
}

function syncOptionRowsValue(container) {
  const fieldKey = container.dataset.field;
  const rows = Array.from(container.querySelectorAll(".option-row")).map((row) => {
    const label = row.querySelector(".option-label")?.value || "";
    const score = row.querySelector(".option-score")?.value || "";
    const id = row.dataset.optionId || uid("tplo");
    row.dataset.optionId = id;
    return { id, label: String(label).trim(), score: String(score).trim() };
  });
  const hidden = container.closest(".form-item")?.querySelector(`input[type="hidden"][data-field="${fieldKey}"]`);
  if (hidden) {
    hidden.value = JSON.stringify(rows);
  }
}

function handleModalFormChange(event) {
  const assessmentSelect = event.target.closest("[data-action='admission-assessment-select']");
  if (assessmentSelect) {
    handleAdmissionAssessmentModalSelect(assessmentSelect);
    return;
  }
  const assessmentOption = event.target.closest("input[data-action='admission-assessment-option']");
  if (assessmentOption) {
    handleAdmissionAssessmentModalOption(assessmentOption);
    return;
  }
  const input = event.target.closest("input[type='file'][data-action]");
  if (!input) return;
  const fieldKey = input.dataset.field;
  const grid = el.modalForm.querySelector(`.image-grid[data-field="${fieldKey}"]`);
  if (!fieldKey || !grid) return;

  const files = Array.from(input.files || []);
  if (!files.length) return;

  const existing = readImageFieldValue(fieldKey);
  readFilesAsDataUrls(files).then((items) => {
    const merged = existing.concat(items);
    renderImageGrid(fieldKey, merged);
  });

  input.value = "";
}

function readFilesAsDataUrls(files) {
  return Promise.all(files.map((file) => new Promise((resolve) => {
    const reader = new FileReader();
    reader.onload = () => resolve({ id: uid("img"), src: String(reader.result || ""), name: file.name || "" });
    reader.onerror = () => resolve(null);
    reader.readAsDataURL(file);
  }))).then((items) => items.filter((item) => item && item.src));
}

function readImageFieldValue(fieldKey) {
  const hidden = el.modalForm.querySelector(`input[type="hidden"][data-field="${fieldKey}"]`);
  if (!hidden) return [];
  return normalizeImageItems(hidden.value || "");
}

function renderImageGrid(fieldKey, items) {
  const grid = el.modalForm.querySelector(`.image-grid[data-field="${fieldKey}"]`);
  const hidden = el.modalForm.querySelector(`input[type="hidden"][data-field="${fieldKey}"]`);
  if (!grid || !hidden) return;
  const normalized = normalizeImageItems(items);
  grid.innerHTML = normalized.map((item) => renderImageThumb(item)).join("");
  hidden.value = JSON.stringify(normalized);
}

function syncImageFieldValue(grid) {
  const fieldKey = grid.dataset.field;
  if (!fieldKey) return;
  const items = Array.from(grid.querySelectorAll(".image-thumb")).map((thumb) => {
    const id = thumb.dataset.imageId || uid("img");
    const img = thumb.querySelector("img");
    return { id, src: img?.getAttribute("src") || "", name: img?.getAttribute("alt") || "" };
  }).filter((item) => item.src);
  renderImageGrid(fieldKey, items);
}

function renderOptionRow(row = {}) {
  const id = row.id || uid("tplo");
  const label = esc(readValue(row.label || ""));
  const score = esc(readValue(row.score || ""));
  return `
    <div class="option-row" data-option-id="${esc(id)}">
      <input class="option-label" type="text" placeholder="选项名称" value="${label}">
      <input class="option-score" type="number" placeholder="分数" value="${score}">
      <button class="mini-btn ghost" type="button" data-action="remove-option-row">移除</button>
    </div>
  `;
}

function normalizeImageItems(value) {
  if (Array.isArray(value)) {
    return value
      .map((item) => ({
        id: item?.id || uid("img"),
        src: String(item?.src || ""),
        name: String(item?.name || "").trim()
      }))
      .filter((item) => !!item.src);
  }
  if (typeof value === "string" && value.trim()) {
    try {
      const parsed = JSON.parse(value);
      return normalizeImageItems(parsed);
    } catch {
      return [];
    }
  }
  return [];
}

function renderImageThumb(item) {
  const name = esc(item.name || "图片");
  return `
    <div class="image-thumb" data-image-id="${esc(item.id)}">
      <img src="${esc(item.src)}" alt="${name}">
      <button class="mini-btn ghost" type="button" data-action="remove-image">移除</button>
    </div>
  `;
}

function enforceCoreFieldRules() {
  const patientAdmissionNo = state.schemas.patient.find((item) => item.key === "admissionNo");
  if (patientAdmissionNo) {
    patientAdmissionNo.required = true;
    patientAdmissionNo.locked = true;
    patientAdmissionNo.showInList = false;
  }

  const admissionAdmitDate = state.schemas.admission.find((item) => item.key === "admitDate");
  if (admissionAdmitDate) {
    admissionAdmitDate.required = true;
    admissionAdmitDate.locked = true;
  }
}

function isCoreRequiredField(moduleKey, key) {
  return (moduleKey === "patient" && key === "admissionNo")
    || (moduleKey === "admission" && key === "admitDate");
}

function hasInHospitalAdmission(admissionNo) {
  if (!admissionNo) return false;
  return state.admissions.some((item) => item.admissionNo === admissionNo && item.status === "在院");
}

function repairLegacyDataArtifacts() {
  const coreSchemaTemplate = {
    patient: [
      { key: "admissionNo", label: "住院号", type: "text", required: true, locked: true, showInList: false },
      { key: "name", label: "姓名", type: "text", required: true, showInList: true },
      { key: "gender", label: "性别", type: "select", options: ["男", "女"], required: true, showInList: true },
      { key: "age", label: "年龄", type: "number", required: true, showInList: true },
      { key: "phone", label: "联系电话", type: "text", required: false, showInList: false }
    ],
    admission: [
      { key: "admitDate", label: "入院日期", type: "date", required: true, locked: true, showInList: true },
      { key: "department", label: "科室", type: "text", required: true, showInList: true },
      { key: "diagnosis", label: "初步诊断", type: "text", required: true, showInList: true },
      { key: "attendingDoctor", label: "主治医生", type: "text", required: true, showInList: false },
      { key: "status", label: "状态", type: "select", options: ["在院", "出院"], required: true, showInList: true }
    ],
    daily: [
      { key: "recordDate", label: "记录日期", type: "date", required: true, showInList: true },
      { key: "temperature", label: "体温(℃)", type: "number", required: false, showInList: true },
      { key: "bloodPressure", label: "血压", type: "text", required: false, showInList: true },
      { key: "notes", label: "病情记录", type: "textarea", required: false, showInList: false }
    ],
    templateDisease: [
      { key: "diseaseCode", label: "病种编码", type: "text", required: false, showInList: true },
      { key: "versionCount", label: "版本数", type: "number", required: false, showInList: true, locked: true, computed: true },
      { key: "itemCount", label: "测评项总数", type: "number", required: false, showInList: true, locked: true, computed: true },
      { key: "description", label: "说明", type: "textarea", required: false, showInList: true }
    ],
    templateVersion: [
      { key: "year", label: "年度", type: "text", required: false, showInList: true },
      { key: "itemCount", label: "测评项", type: "number", required: false, showInList: true, locked: true, computed: true },
      { key: "optionCount", label: "选项数", type: "number", required: false, showInList: true, locked: true, computed: true },
      { key: "gradeCount", label: "分级区间", type: "number", required: false, showInList: true, locked: true, computed: true },
      { key: "description", label: "说明", type: "textarea", required: false, showInList: true }
    ]
  };

  const looksLikeMojibake = (value) => {
    const text = String(value || "").trim();
    if (!text) return false;
    const hints = ["鐥", "娴", "鍒", "璇", "缂", "鎮", "绛", "妯", "瀛楁", "鏈€", "銆?", "宸叉"];
    return hints.some((hint) => text.includes(hint));
  };

  const defaultFieldValue = (field) => {
    if (!field || typeof field !== "object") return "";
    if (field.type === "select") return Array.isArray(field.options) ? (field.options[0] || "") : "";
    if (field.type === "images") return [];
    return "";
  };

  for (const [moduleKey, defaults] of Object.entries(coreSchemaTemplate)) {
    const schema = Array.isArray(state.schemas[moduleKey]) ? state.schemas[moduleKey] : [];
    const byKey = new Map(schema.filter((item) => item && item.key).map((item) => [item.key, { ...item }]));
    const coreKeys = new Set(defaults.map((item) => item.key));

    const normalizedCore = defaults.map((baseField) => {
      const row = byKey.has(baseField.key) ? { ...byKey.get(baseField.key) } : { ...baseField };
      row.key = baseField.key;
      row.type = baseField.type;
      row.required = !!baseField.required || !!row.required;
      if (baseField.locked) row.locked = true;
      if (baseField.computed) row.computed = true;

      if (!String(row.label || "").trim() || looksLikeMojibake(row.label)) {
        row.label = baseField.label;
      }

      if (baseField.type === "select") {
        const options = Array.isArray(row.options) ? row.options.map((opt) => String(opt || "").trim()).filter(Boolean) : [];
        row.options = options.length && !options.some((opt) => looksLikeMojibake(opt))
          ? options
          : [...(baseField.options || [])];
      } else {
        delete row.options;
      }

      if (moduleKey === "patient" && baseField.key === "admissionNo") {
        row.showInList = false;
      } else if (typeof row.showInList !== "boolean") {
        row.showInList = !!baseField.showInList;
      }
      return row;
    });

    const customFields = schema
      .filter((item) => item && item.key && !coreKeys.has(item.key))
      .map((item) => ({ ...item }));

    state.schemas[moduleKey] = [...normalizedCore, ...customFields];
  }

  state.patients = (Array.isArray(state.patients) ? state.patients : []).map((row) => {
    const next = { ...(row || {}) };
    const genderText = String(next.gender || "").trim();
    if (["鐢", "鐢?", "male", "Male", "MALE"].includes(genderText)) next.gender = "男";
    if (["濂", "濂?", "female", "Female", "FEMALE"].includes(genderText)) next.gender = "女";
    for (const field of state.schemas.patient) {
      if (!(field.key in next)) {
        next[field.key] = defaultFieldValue(field);
      }
    }
    return next;
  });

  state.admissions = (Array.isArray(state.admissions) ? state.admissions : []).map((row) => {
    const next = { ...(row || {}) };
    const statusText = String(next.status || "").trim();
    if (["鍦ㄩ櫌", "住院", "住院中", "在院", "院内"].includes(statusText)) next.status = "在院";
    else if (["鍑洪櫌", "已出院", "出院"].includes(statusText)) next.status = "出院";
    else if (!statusText) next.status = "在院";

    for (const field of state.schemas.admission) {
      if (!(field.key in next)) {
        next[field.key] = defaultFieldValue(field);
      }
    }
    next._id = next._id || uid("adm");
    return next;
  });

  const admissionIdSet = new Set(state.admissions.map((row) => row._id));
  state.dailyRecords = (Array.isArray(state.dailyRecords) ? state.dailyRecords : [])
    .map((row) => {
      const next = { ...(row || {}) };
      for (const field of state.schemas.daily) {
        if (!(field.key in next)) {
          next[field.key] = defaultFieldValue(field);
        }
      }
      next._id = next._id || uid("daily");
      return next;
    })
    .filter((row) => admissionIdSet.has(row.admissionId));

  const diseaseSchema = state.schemas.templateDisease || [];
  const versionSchema = state.schemas.templateVersion || [];
  state.templates = (Array.isArray(state.templates) ? state.templates : []).map((disease) => {
    const next = { ...(disease || {}) };
    next.id = next.id || uid("tpld");
    next.versions = Array.isArray(next.versions) ? next.versions : [];

    for (const field of diseaseSchema) {
      if (field.computed) continue;
      if (!(field.key in next)) {
        next[field.key] = defaultFieldValue(field);
      }
    }

    next.versions = next.versions.map((version) => {
      const vNext = { ...(version || {}) };
      vNext.id = vNext.id || uid("tplv");
      vNext.items = Array.isArray(vNext.items) ? vNext.items : [];
      vNext.gradeRules = Array.isArray(vNext.gradeRules) ? vNext.gradeRules : [];

      for (const field of versionSchema) {
        if (field.computed) continue;
        if (!(field.key in vNext)) {
          vNext[field.key] = defaultFieldValue(field);
        }
      }

      return vNext;
    });

    return next;
  });

  if (!state.admissionAssessments || typeof state.admissionAssessments !== "object") {
    state.admissionAssessments = {};
  }
  Object.keys(state.admissionAssessments).forEach((key) => {
    if (!admissionIdSet.has(key)) {
      delete state.admissionAssessments[key];
      return;
    }
    const row = state.admissionAssessments[key];
    if (!row || typeof row !== "object") {
      state.admissionAssessments[key] = { records: [] };
      return;
    }
    if (Array.isArray(row.records)) {
      row.records = row.records
        .filter((record) => record && typeof record === "object")
        .map((record) => ({
          id: record.id || uid("assr"),
          diseaseId: typeof record.diseaseId === "string" ? record.diseaseId : "",
          versionId: typeof record.versionId === "string" ? record.versionId : "",
          selections: record.selections && typeof record.selections === "object" ? record.selections : {},
          createdAt: record.createdAt || new Date().toISOString()
        }));
      return;
    }
    if ("diseaseId" in row || "versionId" in row || "selections" in row) {
      row.records = [{
        id: uid("assr"),
        diseaseId: typeof row.diseaseId === "string" ? row.diseaseId : "",
        versionId: typeof row.versionId === "string" ? row.versionId : "",
        selections: row.selections && typeof row.selections === "object" ? row.selections : {},
        createdAt: row.createdAt || new Date().toISOString()
      }];
      delete row.diseaseId;
      delete row.versionId;
      delete row.selections;
      return;
    }
    row.records = [];
  });

  if (!state.admissionImaging || typeof state.admissionImaging !== "object") {
    state.admissionImaging = {};
  }
  Object.keys(state.admissionImaging).forEach((key) => {
    if (!admissionIdSet.has(key)) {
      delete state.admissionImaging[key];
      return;
    }
    const items = normalizeImageItems(state.admissionImaging[key]);
    if (!items.length) {
      delete state.admissionImaging[key];
      return;
    }
    state.admissionImaging[key] = items;
  });
}

function isFieldVisibleInList(moduleKey, field) {
  if (moduleKey === "patient" && field.key === "admissionNo") return false;
  if (typeof field.showInList === "boolean") return field.showInList;
  return true;
}

function applySchemaCoercion(values, schema) {
  const payload = { ...values };
  (schema || []).forEach((field) => {
    if (field.type === "images") {
      payload[field.key] = normalizeImageItems(values[field.key]);
    }
  });
  return payload;
}

function formatFieldValue(field, value) {
  if (field?.type === "images") {
    const count = normalizeImageItems(value).length;
    return count ? `已上传${count}张` : "未上传";
  }
  return value;
}

function formatDateTime(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  const pad = (num) => String(num).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function fieldItem(key, value, isFull = false) {
  const cls = isFull ? "field-item full" : "field-item";
  return `
    <div class="${cls}">
      <div class="k">${esc(key)}</div>
      <div class="v">${esc(readValue(value) || "-")}</div>
    </div>
  `;
}

function statItem(key, value) {
  return `
    <div class="stat-card">
      <div class="k">${esc(key)}</div>
      <div class="v">${esc(String(value))}</div>
    </div>
  `;
}

function renderInHospitalFilterStat(count, active) {
  return `
    <button
      class="stat-card stat-filter ${active ? "active" : ""}"
      type="button"
      data-action="toggle-in-hospital-filter"
      aria-pressed="${active ? "true" : "false"}"
      title="${active ? "点击取消在院筛选" : "点击筛选在院病人"}"
    >
      <div class="k">在院病人</div>
      <div class="v">${esc(String(count))}</div>
      <div class="hint">${active ? "已筛选 · 点击取消" : "点击筛选"}</div>
    </button>
  `;
}

function getInHospitalPatientNoSet() {
  const set = new Set();
  for (const item of state.admissions) {
    if (item.status === "在院") set.add(item.admissionNo);
  }
  return set;
}

function moduleLabel(key) {
  if (key === "patient") return "病人信息";
  if (key === "admission") return "入院记录";
  if (key === "daily") return "日常记录";
  if (key === "templateDisease") return "病种模板";
  if (key === "templateVersion") return "版本列表";
  return key;
}

function showToast(message) {
  el.toast.textContent = message;
  el.toast.classList.remove("hidden");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    el.toast.classList.add("hidden");
  }, 1300);
}

function uid(prefix) {
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
}

function readValue(v) {
  if (v === null || v === undefined) return "";
  return String(v);
}

function esc(value) {
  return readValue(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}



